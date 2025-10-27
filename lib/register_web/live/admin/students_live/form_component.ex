defmodule RegisterWeb.Admin.StudentsLive.FormComponent do
  use RegisterWeb, :live_component

  alias Register.Students

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
    ~H"""
    <div>
      <.modal id={@id} show={true} on_cancel={JS.navigate(@return_to)}>
        <div class="space-y-6">
          <div class="text-center">
            <h3 class="text-lg font-medium leading-6 text-gray-900" id="modal-title">
              <%= @title %>
            </h3>
          </div>

          <.simple_form
            for={@changeset}
            id="student-form"
            phx-target={@myself}
            phx-change="validate"
            phx-submit="save"
            :let={f}
          >
            <div class="grid grid-cols-6 gap-6">
              <div class="col-span-6 sm:col-span-3">
                <.input
                  field={f[:first_name]}
                  type="text"
                  label="First Name"
                  class="mt-1 block w-full"
                />
              </div>

              <div class="col-span-6 sm:col-span-3">
                <.input
                  field={f[:last_name]}
                  type="text"
                  label="Last Name"
                  class="mt-1 block w-full"
                />
              </div>

              <div class="col-span-6">
                <.input
                  field={f[:email]}
                  type="email"
                  label="Email"
                  class="mt-1 block w-full"
                />
              </div>

              <div class="col-span-6">
                <.input
                  field={f[:program]}
                  type="text"
                  label="Program"
                  class="mt-1 block w-full"
                />
              </div>
            </div>
            <:actions>
              <div class="flex justify-end space-x-2">
                <.button
                  phx-click={JS.navigate(@return_to)}
                  type="button"
                  class="bg-white text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </.button>
                <.button phx-disable-with="Saving...">Save</.button>
              </div>
            </:actions>
          </.simple_form>
        </div>
      </.modal>
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
             |> push_navigate(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, changeset: changeset)}
        end

      :new ->
        case Students.create_student(student_params) do
          {:ok, _student} ->
            {:noreply,
             socket
             |> put_flash(:info, "Student created successfully")
             |> push_navigate(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, changeset: changeset)}
        end
    end
  end
end
