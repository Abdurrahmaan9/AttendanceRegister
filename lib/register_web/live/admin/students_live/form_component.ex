defmodule RegisterWeb.Admin.StudentsLive.FormComponent do
  use RegisterWeb, :live_component
  import RegisterWeb.CoreComponents

  alias Register.Students
  alias Register.Students.Student

  @impl true
  def update(%{student: student} = assigns, socket) do
    changeset = Students.change_student(student, %{})
    title = Map.get(assigns, :title, if(student.id, do: "Edit Student", else: "New Student"))

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:title, title)
     |> assign(:changeset, changeset)
     |> assign_new(:return_to, fn -> ~p"/Admin/students" end)}
  end

  @impl true
  def render(assigns) do
    modal_id = "student-#{@id}"
    ~H"""
    <div id={modal_id} class="fixed z-10 inset-0 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true" phx-remove={JS.hide(to: "##{modal_id}")}>
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <!-- Background overlay -->
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true" phx-click="cancel_edit" phx-target={@myself}></div>

        <!-- This element is to trick the browser into centering the modal contents. -->
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>

        <!-- Modal panel -->
        <div class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
          <div class="absolute top-0 right-0 pt-4 pr-4">
            <button type="button" phx-click="cancel_edit" phx-target={@myself} class="bg-white rounded-md text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              <span class="sr-only">Close</span>
              <!-- Heroicon name: x -->
              <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div class="sm:flex sm:items-start">
            <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
              <h3 class="text-lg leading-6 font-medium text-gray-900" id="modal-title">
                <%= @title %>
              </h3>
              <div class="mt-4">
                <.form
                  :let={f}
                  for={@changeset}
                  id="student-form"
                  phx-submit="save"
                  phx-change="validate"
                  phx-target={@myself}
                  class="space-y-4"
                >
                  <div class="grid grid-cols-6 gap-6">
                    <div class="col-span-6 sm:col-span-3">
                      <label for="first_name" class="block text-sm font-medium text-gray-700">First Name</label>
                      <.input
                        field={f[:first_name]}
                        type="text"
                        label="First Name"
                        class="mt-1 block w-full"
                      />
                    </div>

                    <div class="col-span-6 sm:col-span-3">
                      <label for="last_name" class="block text-sm font-medium text-gray-700">Last Name</label>
                      <.input
                        field={f[:last_name]}
                        type="text"
                        label="Last Name"
                        class="mt-1 block w-full"
                      />
                    </div>

                    <div class="col-span-6">
                      <label for="email" class="block text-sm font-medium text-gray-700">Email</label>
                      <.input
                        field={f[:email]}
                        type="email"
                        label="Email"
                        class="mt-1 block w-full"
                      />
                    </div>

                    <div class="col-span-6">
                      <label for="program" class="block text-sm font-medium text-gray-700">Program</label>
                      <.input
                        field={f[:program]}
                        type="text"
                        label="Program"
                        class="mt-1 block w-full"
                      />
                    </div>
                  </div>
                </.form>
              </div>
            </div>
          </div>
          <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
            <button
              type="submit"
              form="student-form"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm"
            >
              Save
            </button>
            <button
              type="button"
              phx-click="cancel_edit"
              phx-target={@myself}
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"student" => student_params}, socket) do
    changeset =
      socket.assigns.student
      |> Students.change_student(student_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("cancel_edit", _, socket) do
    {:noreply,
     socket
     |> push_patch(to: socket.assigns.return_to)
     |> push_event("phx:close_modal", %{id: socket.assigns.id})}
  end

  def handle_event("save", %{"student" => student_params}, socket) do
    case socket.assigns.action do
      :edit ->
        case Students.update_student(socket.assigns.student, student_params) do
          {:ok, _student} ->
            {:noreply,
             socket
             |> put_flash(:info, "Student updated successfully")
             |> push_redirect(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, changeset: changeset)}
        end

      :new ->
        case Students.create_student(student_params) do
          {:ok, _student} ->
            {:noreply,
             socket
             |> put_flash(:info, "Student created successfully")
             |> push_redirect(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, changeset: changeset)}
        end
    end
  end
end
