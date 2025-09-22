defmodule RegisterWeb.Admin.Dashboard.Index do
  use RegisterWeb, :live_view
  alias Register.Students
  # alias RegisterWeb.Helpers.RoleHelper

  # Import the role helper functions
  # import RegisterWeb.Helpers.RoleHelper, only: [role_class: 1]

  @url "/Admin/dashboard"

  @impl true
  def mount(_params, _session, socket) do
    total_students = Students.count_students()

    socket =
      socket
      |> assign(:current_path, @url)
      |> assign(:sidebar_open, false)
      |> assign(:total_students, total_students)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end
end
