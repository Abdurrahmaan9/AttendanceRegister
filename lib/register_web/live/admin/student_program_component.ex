defmodule RegisterWeb.Admin.StudentProgramComponent do
  use RegisterWeb, :live_component
  alias Register.Academic
  alias Register.Academic.StudentProgram

  @impl true
  @semesters ["1", "2"]
  @current_year Date.utc_today().year
  @academic_years Enum.map(@current_year-2..@current_year+1, &{"#{&1}-#{&1+1}", "#{&1}-#{&1+1}"})

  def update(assigns, socket) do
    changeset =
      %StudentProgram{
        enrollment_date: Date.utc_today(),
        semester: "1",
        academic_year: "#{@current_year}-#{@current_year+1}"
      }
      |> StudentProgram.changeset(%{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:students, list_students())
     |> assign(:programs, list_programs())
     |> assign(:semesters, @semesters)
     |> assign(:academic_years, @academic_years)
     |> assign(:student_programs, list_student_programs(assigns.student_id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white shadow overflow-hidden sm:rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <h3 class="text-lg leading-6 font-medium text-gray-900">
          Program Enrollment
        </h3>
        <p class="mt-1 max-w-2xl text-sm text-gray-500">
          Manage student's program enrollment
        </p>
      </div>

      <%= if Enum.empty?(@student_programs) do %>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <.form :let={f} for={@changeset} phx-submit="save" phx-target={@myself} class="space-y-6">
            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
              <%= if !@student_id do %>
                <div class="sm:col-span-3">
                  <.input
                    field={f[:student_id]}
                    type="select"
                    label="Student"
                    options={@students}
                    required
                  />
                </div>
              <% else %>
                <input type="hidden" name="student_program[student_id]" value={@student_id} id="student_program_student_id" />
              <% end %>

              <div class="sm:col-span-3">
                <.input
                  field={f[:program_id]}
                  type="select"
                  label="Program"
                  options={@programs}
                  required
                />
              </div>

              <div class="sm:col-span-2">
                <.input
                  field={f[:enrollment_date]}
                  type="date"
                  label="Enrollment Date"
                  required
                />
              </div>

              <div class="sm:col-span-2">
                <.input
                  field={f[:semester]}
                  type="select"
                  label="Semester"
                  options={@semesters}
                  required
                />
              </div>

              <div class="sm:col-span-2">
                <.input
                  field={f[:academic_year]}
                  type="select"
                  label="Academic Year"
                  options={@academic_years}
                  required
                />
              </div>

              <div class="sm:col-span-2">
                <.input
                  field={f[:graduation_date]}
                  type="date"
                  label="Graduation Date (Optional)"
                />
              </div>

              <div class="sm:col-span-2 flex items-end">
                <.button type="submit" variant={:primary}>
                  Assign Program
                </.button>
              </div>
            </div>
          </.form>
        </div>
      <% end %>

      <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
        <h4 class="text-sm font-medium text-gray-500 mb-4">Current Program Enrollments</h4>

        <%= if Enum.empty?(@student_programs) do %>
          <p class="text-sm text-gray-500">No program enrollments found.</p>
        <% else %>
          <div class="overflow-hidden bg-white shadow sm:rounded-md">
            <ul role="list" class="divide-y divide-gray-200">
              <%= for enrollment <- @student_programs do %>
                <li>
                  <div class="px-4 py-4 sm:px-6">
                    <div class="flex items-center justify-between">
                      <p class="truncate text-sm font-medium text-blue-600">
                        <%= enrollment.program.name %>
                      </p>
                      <div class="ml-2 flex flex-shrink-0">
                        <p class="inline-flex rounded-full bg-green-100 px-2 text-xs font-semibold leading-5 text-green-800">
                          <%= enrollment.semester %> - <%= enrollment.academic_year %>
                        </p>
                      </div>
                    </div>
                    <div class="mt-2 sm:flex sm:justify-between">
                      <div class="sm:flex">
                        <p class="flex items-center text-sm text-gray-500">
                          Enrolled on <%= Calendar.strftime(enrollment.enrollment_date, "%B %d, %Y") %>
                        </p>
                      </div>
                      <%= if enrollment.graduation_date do %>
                        <div class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                          <svg class="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                            <path fill-rule="evenodd" d="M5.75 2a.75.75 0 01.75.75V4h7V2.75a.75.75 0 011.5 0V4h.25A2.75 2.75 0 0118 6.75v8.5A2.75 2.75 0 0115.25 18H4.75A2.75 2.75 0 012 15.25v-8.5A2.75 2.75 0 014.75 4H5V2.75A.75.75 0 015.75 2zm-1 5.5c-.69 0-1.25.56-1.25 1.25v6.5c0 .69.56 1.25 1.25 1.25h10.5c.69 0 1.25-.56 1.25-1.25v-6.5c0-.69-.56-1.25-1.25-1.25H4.75z" clip-rule="evenodd" />
                          </svg>
                          Graduation: <%= Calendar.strftime(enrollment.graduation_date, "%B %d, %Y") %>
                        </div>
                      <% end %>
                    </div>
                    <div class="mt-2 flex justify-between items-center">
                      <span class={["px-2 inline-flex text-xs leading-5 font-semibold rounded-full",
                        if(enrollment.is_active, do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800")]}>
                        <%= if enrollment.is_active, do: "Active", else: "Inactive" %>
                      </span>
                      <.button
                        phx-click="delete"
                        phx-value-id={enrollment.id}
                        phx-target={@myself}
                        variant={:danger}
                        size={:sm}
                        data-confirm="Are you sure you want to remove this program assignment?"
                      >
                        Remove
                      </.button>
                    </div>
                  </div>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
  @impl true
  def handle_event("save", %{"student_program" => student_program_params}, socket) do
    case Academic.create_student_program(student_program_params) do
      {:ok, _student_program} ->
        {:noreply,
         socket
         |> put_flash(:info, "Program assigned successfully")
         |> assign(:changeset, StudentProgram.changeset(%StudentProgram{}, %{}))
         |> assign(:student_programs, list_student_programs(socket.assigns.student_id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    student_program = Academic.get_student_program!(id)
    {:ok, _} = Academic.delete_student_program(student_program)

    {:noreply,
     socket
     |> put_flash(:info, "Program assignment removed")
     |> assign(:student_programs, list_student_programs(socket.assigns.student_id))}
  end

  defp list_students do
    Register.Accounts.list_users_by_role("student")
    |> Enum.map(&{"#{&1.email} (##{&1.id})", &1.id})
  end

  defp list_programs do
    Academic.list_programs()
    |> Enum.map(&{"#{&1.name} (#{&1.code})", &1.id})
  end

  defp list_student_programs(student_id) when is_binary(student_id) do
    student_id
    |> String.to_integer()
    |> list_student_programs()
  end

  defp list_student_programs(student_id) when is_integer(student_id) do
    Academic.list_student_programs(student_id)
  end
end
