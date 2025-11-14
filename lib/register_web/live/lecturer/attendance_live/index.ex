defmodule RegisterWeb.Lecturer.AttendanceLive.Index do
  use RegisterWeb, :live_view

  alias Register.Attendance
  alias Register.Academic

  @impl true
  def mount(_params, session, socket) do
    current_user = get_session_user(session)
    
    programs = if current_user, do: Academic.list_lecturer_programs(current_user.id), else: []
    courses = []
    
    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:sidebar_open, false)
      |> assign(:page_title, "Attendance View")
      |> assign(:programs, programs)
      |> assign(:courses, courses)
      |> assign(:selected_program_id, nil)
      |> assign(:selected_course_id, nil)
      |> assign(:summary, %{sessions: []})
      |> assign(:module_stats, %{})
      |> assign(:current_module_stats, %{})

    if connected?(socket) and current_user do
      {:ok, load_data(socket)}
    else
      {:ok, socket}
    end
  end

  defp get_session_user(session) do
    case session["user_token"] do
      nil -> nil
      token -> Register.Accounts.get_user_by_session_token(token)
    end
  end

  defp load_data(%{assigns: %{current_user: %{id: lecturer_id}}} = socket) do
    summary = Attendance.list_recent_scans_for_lecturer(lecturer_id)
    
    # Get all unique module codes from the summary
    module_codes = 
      summary.sessions
      |> Enum.map(& &1.module_code)
      |> Enum.uniq()
    
    # Get stats for each module
    module_stats = 
      module_codes
      |> Enum.map(fn module_code ->
        stats = Register.Attendance.get_module_stats(module_code)
        {module_code, stats}
      end)
      |> Map.new()
    
    # Get the first module's stats for the main display
    current_module_stats = 
      case Enum.take(module_stats, 1) |> List.first() do
        {_module_code, stats} -> stats
        nil -> %{}
      end
    
    socket
    |> assign(:summary, summary)
    |> assign(:module_stats, module_stats)
    |> assign(:current_module_stats, current_module_stats)
  end

  defp load_data(socket), do: socket

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:page_title, "Attendance View")
  end

  @impl true
  def handle_event("select_program", %{"program_id" => program_id_str}, socket) do
    program_id = parse_int(program_id_str)
    courses =
      case program_id do
        nil -> []
        id -> Academic.list_lecturer_courses(socket.assigns.current_user.id, id)
      end

    summary = Attendance.lecturer_attendance_summary(%{
      lecturer_id: socket.assigns.current_user.id,
      program_id: program_id,
      course_id: nil
    })

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

    summary = Attendance.lecturer_attendance_summary(%{
      lecturer_id: socket.assigns.current_user.id,
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
end
