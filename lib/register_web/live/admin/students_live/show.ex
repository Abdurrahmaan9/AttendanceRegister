defmodule RegisterWeb.Admin.StudentsLive.Show do
  use RegisterWeb, :live_view
  alias Register.Students
  alias Register.Academic

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    student = Students.get_student!(id)
    student_courses = Academic.list_student_courses(student.id)

    {:noreply,
     socket
     |> assign(:page_title, "Student: #{student.email}")
     |> assign(:student, student)
     |> assign(:student_courses, student_courses)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="flex justify-between items-center">
            <div>
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Student Information
              </h3>
              <p class="mt-1 max-w-2xl text-sm text-gray-500">
                Personal details and information
              </p>
            </div>
            <.link
              navigate={~p"/Admin/students"}
              class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Back to Students
            </.link>
          </div>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:p-0">
          <dl class="sm:divide-y sm:divide-gray-200">
            <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Email</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <%= @student.email %>
              </dd>
            </div>
            <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">First Name</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <%= @student.first_name %>
              </dd>
            </div>
            <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Last_name</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <%= @student.last_name %>
              </dd>
            </div>
            <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Program</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">
                  <%= String.capitalize(@student.program) %>
                </span>
              </dd>
            </div>
          </dl>
        </div>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Courses Assigned
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Active courses from the student's active program enrollments
          </p>
        </div>
        <div class="border-t border-gray-200">
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Course</th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Code</th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Course Points</th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Year</th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Semester</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= if Enum.empty?(@student_courses || []) do %>
                  <tr>
                    <td colspan="4" class="px-6 py-4 text-sm text-gray-500">No active courses found.</td>
                  </tr>
                <% else %>
                  <%= for sc <- @student_courses do %>
                    <tr>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900"><%= sc.course.title %></td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= sc.course.code %></td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= sc.course.credits %></td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= sc.year %></td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= sc.semester %></td>
                    </tr>
                  <% end %>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <.live_component
        module={RegisterWeb.Admin.StudentProgramComponent}
        id="student-programs"
        student_id={@student.id}
      />
    </div>
    """
  end
end
