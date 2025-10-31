defmodule RegisterWeb.Students.AttendanceLive.Index do
  use RegisterWeb, :live_view

  alias Register.Attendance
  alias Register.Students

  @impl true
  def mount(_params, session, socket) do
    current_user = get_session_user(session)
    current_student = if current_user, do: Students.get_student_by_email(current_user.email)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:current_student, current_student)
      |> assign(:summary, nil)
      |> assign(:sidebar_open, false)
      |> assign(:page_title, "Attendance Overview")

    if connected?(socket) and current_student do
      {:ok, load_summary(socket)}
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

  defp load_summary(%{assigns: %{current_student: %{id: student_id}}} = socket) do
    summary = Attendance.student_attendance_summary(student_id)
    assign(socket, :summary, summary)
  end

  defp load_summary(socket), do: socket

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Attendance Overview")
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end
end
