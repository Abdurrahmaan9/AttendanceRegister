defmodule RegisterWeb.Admin.CoursesLive.Index do
  use RegisterWeb, :live_view
  import RegisterWeb.Utils
  alias Register.Courses
  alias Register.Courses.Course

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:courses, list_courses())
      |> assign(:sidebar_open, false)
      |> assign(:loading, !connected?(socket))

    if connected?(socket), do: send(self(), {:courses, list_courses()})

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Courses")
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Courses")
    |> assign(:course, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Course")
    |> assign(:course, %Course{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Course")
    |> assign(:course, Courses.get_course!(id))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    course = Courses.get_course!(id)
    {:ok, _} = Courses.delete_course(course)

    {:noreply, assign(socket, :courses, list_courses())}
  end

  defp list_courses do
    Courses.list_courses()
  end

  @impl true
  def handle_info({:courses, courses}, socket) do
    {:noreply, socket |> assign(:courses, courses) |> assign(:loading, false)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end
end
