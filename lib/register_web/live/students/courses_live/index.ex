defmodule RegisterWeb.Students.CoursesLive.Index do
  use RegisterWeb, :live_view

  alias Register.Academic

  @impl true
  def mount(_params, session, socket) do
    current_user = get_session_user(session)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:courses, [])
      |> assign(:student_programs, [])
      |> assign(:sidebar_open, false)
      |> assign(:page_title, "My Courses")

    socket =
      if current_user do
        load_courses(socket)
      else
        socket
      end

    {:ok, socket}
  end

  defp get_session_user(session) do
    case session["user_token"] do
      nil -> nil
      token -> Register.Accounts.get_user_by_session_token(token)
    end
  end

  defp load_courses(%{assigns: %{current_user: %{id: user_id}}} = socket) do
    student_programs =
      Academic.list_student_programs(user_id)
      |> Enum.filter(& &1.is_active)

    courses =
      case student_programs do
        [] -> []
        _ -> Academic.list_student_courses(user_id)
      end

    socket
    |> assign(:student_programs, student_programs)
    |> assign(:courses, courses)
  end

  defp load_courses(socket), do: socket

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Courses")
    |> load_courses()
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end
end
