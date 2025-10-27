defmodule RegisterWeb.Lecturer.AttendanceLive.Index do
  use RegisterWeb, :live_view

  alias Register.Attendance

  @impl true
  def mount(_params, session, socket) do
    current_user = get_session_user(session)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:sidebar_open, false)
      |> assign(:page_title, "Attendance View")
      |> assign(:summary, nil)

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
    assign(socket, :summary, summary)
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
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end
end
