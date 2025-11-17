defmodule RegisterWeb.Admin.LecturerLive.CoursesLive.Index do
  use RegisterWeb, :live_view

  alias Register.Academic
  alias Register.Accounts
  alias Register.Courses.Course
  alias Register.Academic.LecturerCourse

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :lecturers, Academic.list_lecturers_with_courses())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Manage Lecturer Courses")
    |> assign(:lecturer_course, nil)
  end

  defp apply_action(socket, :edit, %{"id" => user_id}), do: apply_action(socket, :edit, %{"user_id" => user_id})
  defp apply_action(socket, :edit, %{"user_id" => user_id}) do
    case Academic.get_lecturer_with_courses(user_id) do
      nil ->
        socket
        |> put_flash(:error, "Lecturer not found")
        |> push_navigate(to: ~p"/Admin/lecturers")

      lecturer ->
        unassigned_courses = Academic.list_unassigned_courses(user_id)
        socket
        |> assign(:page_title, "Edit Lecturer Courses")
        |> assign(:lecturer, lecturer)
        |> assign(:unassigned_courses, unassigned_courses)
    end
  end

  @impl true
  def handle_event("assign_course", %{"user_id" => user_id, "course_id" => course_id}, socket) do
    case Academic.assign_lecturer_to_course(user_id, course_id) do
      {:ok, _lecturer_course} ->
        lecturer = Academic.get_lecturer_with_courses(user_id)
        unassigned_courses = Academic.list_unassigned_courses(user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Course assigned successfully")
         |> assign(:lecturer, lecturer)
         |> assign(:unassigned_courses, unassigned_courses)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to assign course")}
    end
  end

  def handle_event("remove_course", %{"user_id" => user_id, "course_id" => course_id}, socket) do
    case Academic.remove_lecturer_from_course(user_id, course_id) do
      :ok ->
        lecturer = Academic.get_lecturer_with_courses(user_id)
        unassigned_courses = Academic.list_unassigned_courses(user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Course removed successfully")
         |> assign(:lecturer, lecturer)
         |> assign(:unassigned_courses, unassigned_courses)}
    end
  end

  def handle_event("set_primary", %{"user_id" => user_id, "course_id" => course_id}, socket) do
    import Ecto.Query

    # First, reset all primary flags for this user
    query = from(lc in LecturerCourse, where: lc.user_id == ^user_id)
    Register.Repo.update_all(query, set: [is_primary: false])

    # Then set the selected course as primary
    query = from(lc in LecturerCourse,
      where: lc.user_id == ^user_id and lc.course_id == ^course_id)
    Register.Repo.update_all(query, set: [is_primary: true])

    lecturer = Academic.get_lecturer_with_courses(user_id)

    {:noreply,
     socket
     |> put_flash(:info, "Primary course updated")
     |> assign(:lecturer, lecturer)}
  end
end
