defmodule RegisterWeb.Admin.ProgramLive.ProgramCoursesComponent do
  use RegisterWeb, :live_component
  use Phoenix.Component
  import Ecto.Query, warn: false

  alias Register.Academic
  alias Register.Academic.Program
  alias RegisterWeb.Utils

  @impl true
  def update(%{program: program} = assigns, socket) do
    socket =
      socket
      |> assign(:program, program)
      |> assign(:available_courses, Academic.list_courses_not_in_program(program.id))
      |> assign(:years, 1..program.duration_years)
      |> assign(:semesters, 1..2)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6 relative">
      <%!-- Header with Close Button --%>
      <div class="flex justify-between items-start">
        <div>
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Manage Courses - <%= @program.name %>
          </h3>
          <p class="mt-1 text-sm text-gray-500">
            Add or remove courses from this program.
          </p>
        </div>

        <%!-- Top Right Close Button --%>
        <.link
          href={~p"/Admin/programs"}
          class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </.link>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h4 class="text-md font-medium text-gray-900 mb-4">Add Course</h4>

          <.form :let={f} for={%{}} as={:course} phx-submit="add_course" phx-target={@myself} class="space-y-4">
            <input type="hidden" name="program_id" value={@program.id} />

            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div class="col-span-2">
                <label for="course_id" class="block text-sm font-medium text-gray-700">Course</label>
                <select
                  id="course_id"
                  name="course_id"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                  required
                >
                  <option value="">Select a course</option>
                  <%= for course <- @available_courses do %>
                    <option value={course.id}><%= course.code %> - <%= course.title %></option>
                  <% end %>
                </select>
              </div>

              <div>
                <label for="year" class="block text-sm font-medium text-gray-700">Year</label>
                <select
                  id="year"
                  name="year"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                  required
                >
                  <%= for year <- @years do %>
                    <option value={year}><%= year %></option>
                  <% end %>
                </select>
              </div>

              <div>
                <label for="semester" class="block text-sm font-medium text-gray-700">Semester</label>
                <select
                  id="semester"
                  name="semester"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                  required
                >
                  <%= for semester <- @semesters do %>
                    <option value={semester}><%= semester %></option>
                  <% end %>
                </select>
              </div>
            </div>

            <div class="flex justify-end">
              <.button type="submit" variant={:primary}>
                Add Course
              </.button>
            </div>
          </.form>
        </div>

        <div class="border-t border-gray-200">
          <div class="px-4 py-5 sm:p-6">
            <h4 class="text-md font-medium text-gray-900 mb-4">Program Courses</h4>

            <div class="space-y-4">
              <%= for year <- @years do %>
                <div>
                  <h5 class="text-sm font-medium text-gray-700 mb-2">Year <%= year %></h5>
                  <%= for semester <- @semesters do %>
                    <div class="mb-4">
                      <h6 class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2">Semester <%= semester %></h6>
                      <ul class="space-y-2">
                        <%= for pc <- get_courses_by_year_and_semester(@program.id, year, semester) do %>
                          <li class="flex justify-between items-center bg-gray-50 px-3 py-2 rounded-md">
                            <div>
                              <span class="font-medium"><%= pc.course.code %></span>
                              <span class="text-gray-500 ml-2"><%= pc.course.title %></span>
                              <%= if pc.is_core do %>
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 ml-2">
                                  Core
                                </span>
                              <% end %>
                            </div>
                            <.button
                              phx-click="remove_course"
                              phx-value-id={pc.id}
                              phx-target={@myself}
                              variant={:danger}
                              size={:sm}
                            >
                              Remove
                            </.button>
                          </li>
                        <% end %>
                        <%= if Enum.empty?(get_courses_by_year_and_semester(@program.id, year, semester)) do %>
                          <li class="text-sm text-gray-500 italic">No courses added yet</li>
                        <% end %>
                      </ul>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse border-t border-gray-200">
          <.link navigate={~p"/Admin/programs"} class="inline-flex items-center justify-center bg-gradient-to-r from-teal-500 to-teal-600 text-white hover:from-teal-600 hover:to-teal-700 border-0 px-6 py-2 rounded-md w-full h-10">
            Done
          </.link>
        </div>
      </div>
    </div>
    """
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
         |> put_flash(:info, "Course added successfully")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to add course")}
    end
  end

  @impl true
  def handle_event("remove_course", %{"id" => id}, %{assigns: %{program: program}} = socket) do
    program_course = Academic.get_program_course!(id)
    {:ok, _} = Academic.delete_program_course(program_course)

    {:noreply,
     socket
     |> put_flash(:info, "Course removed from program")}
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
