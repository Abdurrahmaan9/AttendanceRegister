defmodule RegisterWeb.Admin.CoursesLive.FormComponent do
  use RegisterWeb, :live_component

  import RegisterWeb.CoreComponents

  alias Register.Courses



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
                  field={f[:title]}
                  type="text"
                  label="Title"
                  class="mt-1 block w-full"
                />
              </div>

              <div class="col-span-6 sm:col-span-3">
                <.input
                  field={f[:code]}
                  type="text"
                  label="Code"
                  class="mt-1 block w-full"
                />
              </div>

              <div class="col-span-6">
                <.input
                  field={f[:description]}
                  type="textarea"
                  label="Description"
                  class="mt-1 block w-full"
                  rows="3"
                />
              </div>

              <div class="col-span-6 sm:col-span-3">
                <.input
                  field={f[:credits]}
                  type="number"
                  label="Credits"
                  class="mt-1 block w-full"
                />
              </div>

              <div class="col-span-6 sm:col-span-3 flex items-center">
                <.input
                  field={f[:is_active]}
                  type="checkbox"
                  label="Active"
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
              </div>
            </div>

            <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
              <button
                type="submit"
                class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:col-start-2 sm:text-sm"
              >
                Save
              </button>
              <.link
                patch={@return_to}
                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:col-start-1 sm:text-sm"
              >
                Cancel
              </.link>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{course: course} = assigns, socket) do
    changeset = Courses.change_course(course)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"course" => course_params}, socket) do
    changeset =
      socket.assigns.course
      |> Courses.change_course(course_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"course" => course_params}, socket) do
    save_course(socket, socket.assigns.action, course_params)
  end

  defp save_course(socket, :edit, course_params) do
    case Courses.update_course(socket.assigns.course, course_params) do
      {:ok, _course} ->
        {:noreply,
         socket
         |> put_flash(:info, "Course updated successfully")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_course(socket, :new, course_params) do
    case Courses.create_course(course_params) do
      {:ok, _course} ->
        {:noreply,
         socket
         |> put_flash(:info, "Course created successfully")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
