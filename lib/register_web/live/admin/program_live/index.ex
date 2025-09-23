defmodule RegisterWeb.Admin.ProgramLive.Index do
  use RegisterWeb, :live_view
  use Phoenix.Component
  import Ecto.Query, warn: false

  alias Register.Academic
  alias Register.Academic.Program

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :programs, list_programs())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Programs")
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Programs")
    |> assign(:program, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Program")
    |> assign(:program, %Program{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Program")
    |> assign(:program, Academic.get_program!(id))
  end

  defp apply_action(socket, :manage_courses, %{"id" => id}) do
    program = Academic.get_program!(id)

    socket
    |> assign(:page_title, "Manage Courses - #{program.name}")
    |> assign(:program, program)
    |> assign(:available_courses, Academic.list_courses_not_in_program(program.id))
    |> assign(:years, 1..program.duration_years)
    |> assign(:semesters, 1..2)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    program = Academic.get_program!(id)
    {:ok, _} = Academic.delete_program(program)

    {:noreply, assign(socket, :programs, list_programs())}
  end

  @impl true
  def handle_event("add_course", %{"course_id" => course_id, "year" => year, "semester" => semester}, %{assigns: %{program: program}} = socket) do
    attrs = %{
      program_id: program.id,
      course_id: course_id,
      year: String.to_integer(year),
      semester: String.to_integer(semester)
    }

    case Academic.create_program_course(attrs) do
      {:ok, _program_course} ->
        {:noreply,
         socket
         |> put_flash(:info, "Course added successfully")
         |> push_navigate(to: "/Admin/programs/#{program.id}/manage_courses")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to add course")
         |> push_navigate(to: "/Admin/programs/#{program.id}/manage_courses")}
    end
  end

  @impl true
  def handle_event("remove_course", %{"id" => id}, %{assigns: %{program: program}} = socket) do
    program_course = Academic.get_program_course!(id)
    {:ok, _} = Academic.delete_program_course(program_course)

    {:noreply,
     socket
     |> put_flash(:info, "Course removed from program")
     |> push_navigate(to: "/Admin/programs/#{program.id}/manage_courses")}
  end

  defp list_programs do
    Academic.list_programs()
  end

  def status_pill(assigns) do
    ~H"""
    <span class={"#{if assigns[:active], do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800"} inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"}>
      <%= if assigns[:active], do: "Active", else: "Inactive" %>
    </span>
    """
  end

  defp get_courses_by_year_and_semester(program_id, year, semester) do
    from(pc in Register.Academic.ProgramCourse,
      where: pc.program_id == ^program_id and pc.year == ^year and pc.semester == ^semester,
      preload: [:course],
      order_by: [asc: :is_core, asc: :id]
    )
    |> Register.Repo.all()
  end
end
