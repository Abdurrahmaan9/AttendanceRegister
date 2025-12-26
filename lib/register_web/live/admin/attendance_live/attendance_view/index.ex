defmodule RegisterWeb.Admin.AttendanceLive.AttendanceView.Index do
  use RegisterWeb, :live_view

  alias Register.Academic
  alias Register.Attendance

  @impl true
  def mount(_params, session, socket) do
    current_user = get_session_user(session)

    programs = Academic.list_programs()
    courses = []

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:sidebar_open, false)
      |> assign(:page_title, "Student Attendance Performance")
      |> assign(:programs, programs)
      |> assign(:courses, courses)
      |> assign(:selected_program_id, nil)
      |> assign(:selected_course_id, nil)
      |> assign(:summary, nil)

    {:ok, socket}
  end

  defp get_session_user(session) do
    case session["user_token"] do
      nil -> nil
      token -> Register.Accounts.get_user_by_session_token(token)
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:page_title, "Student Attendance Performance")
  end

  @impl true
  def handle_event("select_program", %{"program_id" => program_id_str}, socket) do
    program_id = parse_int(program_id_str)
    courses =
      case program_id do
        nil -> []
        id -> Academic.list_program_courses(id) |> Enum.map(& &1.course)
      end

    summary = Attendance.admin_attendance_summary(%{program_id: program_id, course_id: nil})

    {:noreply,
     socket
     |> assign(:selected_program_id, program_id)
     |> assign(:selected_course_id, nil)
     |> assign(:courses, courses)
     |> assign(:summary, summary)}
  end

  @impl true
  def handle_event("select_course", %{"course_id" => course_id_str}, socket) do
    course_id = parse_int(course_id_str)

    summary =
      Attendance.admin_attendance_summary(%{
        program_id: socket.assigns.selected_program_id,
        course_id: course_id
      })

    {:noreply,
     socket
     |> assign(:selected_course_id, course_id)
     |> assign(:summary, summary)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil
  defp parse_int(str) when is_binary(str), do: String.to_integer(str)

  defp get_performance_color(rate) do
    cond do
      rate >= 95 -> "text-green-600 bg-green-100"
      rate >= 85 -> "text-blue-600 bg-blue-100"
      rate >= 75 -> "text-yellow-600 bg-yellow-100"
      true -> "text-red-600 bg-red-100"
    end
  end

  defp get_performance_label(rate) do
    cond do
      rate >= 95 -> "Excellent"
      rate >= 85 -> "Good"
      rate >= 75 -> "Average"
      true -> "Needs Improvement"
    end
  end
end
