defmodule RegisterWeb.Admin.ProgramLive.FormComponent do
  use RegisterWeb, :live_component

  alias Register.Academic
  alias Register.Academic.Program
  import RegisterWeb.CoreComponents


  @impl true
  def update(%{program: program} = assigns, socket) do
    changeset = Program.changeset(program, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:title, if(program.id, do: "Edit Program", else: "New Program"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
      <div class="sm:flex sm:items-start">
        <div class="w-full">
          <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
            <%= @title %>
          </h3>
          <.form
            :let={f}
            for={@changeset}
            phx-submit="save"
            phx-change="validate"
            phx-target={@myself}
            class="space-y-4"
          >
            <div class="grid grid-cols-6 gap-6">
              <div class="col-span-6 sm:col-span-3">
                <.input
                  field={f[:name]}
                  type="text"
                  label="Program Name"
                  placeholder="e.g. Computer Science"
                  class="mt-1 block w-full"
                />
              </div>

              <div class="col-span-6 sm:col-span-3">
                <.input
                  field={f[:code]}
                  type="text"
                  label="Program Code"
                  placeholder="e.g. CS"
                  class="mt-1 block w-full"
                />
              </div>

              <div class="col-span-6">
                <.input
                  field={f[:description]}
                  type="textarea"
                  label="Description"
                  rows={3}
                  placeholder="Program description..."
                  class="mt-1 block w-full"
                />
              </div>

              <div class="col-span-6 sm:col-span-3">
                <.input
                  field={f[:duration_years]}
                  type="number"
                  label="Duration (Years)"
                  min={1}
                  max={6}
                  class="mt-1 block w-full"
                />
              </div>

              <div class="col-span-6 sm:col-span-3">
                <.input
                  field={f[:is_active]}
                  type="checkbox"
                  label="Active"
                  class="mt-1"
                />
              </div>
            </div>

            <div class="mt-6 flex items-center justify-end space-x-3">
              <.button type="submit" class="bg-indigo-600 hover:bg-indigo-700">
                Save
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </div>

    """
  end

  @impl true
  def handle_event("validate", %{"program" => program_params}, socket) do
    changeset =
      socket.assigns.program
      |> Program.changeset(program_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"program" => program_params}, socket) do
    save_program(socket, socket.assigns.action, program_params)
  end

  def handle_event("cancel", _, socket) do
    {:noreply, push_navigate(socket, to: socket.assigns.return_to)}

  end

  defp save_program(socket, :edit, program_params) do
    case Academic.update_program(socket.assigns.program, program_params) do
      {:ok, _program} ->
        {:noreply,
         socket
         |> put_flash(:info, "Program updated successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_program(socket, :new, program_params) do
    case Academic.create_program(program_params) do
      {:ok, _program} ->
        {:noreply,
         socket
         |> put_flash(:info, "Program created successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
