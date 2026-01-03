defmodule RegisterWeb.LibraryLive.BoardFormComponent do
  use RegisterWeb, :live_component

  alias Register.Library

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-gray-900 mb-6">Create New Board</h2>

      <.form
        for={@form}
        id="library-board-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <div>
          <label class="block text-sm font-medium text-gray-700">
            Board Title
          </label>
          <.input field={@form[:title]} type="text" placeholder="Enter board title" class="w-full mt-1" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700">
            Subtitle (optional)
          </label>
          <.input field={@form[:subtitle]} type="text" placeholder="Enter board subtitle" class="w-full mt-1" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700">
            Description
          </label>
          <.input field={@form[:description]} type="textarea" placeholder="Describe what this board is for" class="w-full h-32 mt-1" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700">
            Cover Image URL (optional)
          </label>
          <.input field={@form[:cover_image_url]} type="text" placeholder="https://example.com/image.jpg" class="w-full mt-1" />
        </div>

        <div class="flex items-center">
          <.input field={@form[:is_public]} type="checkbox" class="h-4 w-4 text-teal-600 border-gray-300 rounded focus:ring-teal-500" />
          <label class="ml-2 text-sm text-gray-700">
            Make this board public
          </label>
        </div>

        <div class="flex justify-end pt-6 space-x-4">
          <.link
            patch={@patch}
            class="bg-gray-300 hover:bg-gray-400 text-gray-800 px-4 py-2 rounded-md text-sm font-medium transition-colors"
          >
            Cancel
          </.link>
          <.button phx-disable-with="Creating...">Create Board</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{board: board} = assigns, socket) do
    changeset = Library.change_library_board(board)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"library_board" => board_params}, socket) do
    changeset =
      socket.assigns.board
      |> Library.change_library_board(board_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"library_board" => board_params}, socket) do
    save_board(socket, socket.assigns.action, board_params)
  end

  defp save_board(socket, :new_board, board_params) do
    board_params = Map.put(board_params, "created_by_id", socket.assigns.current_user.id)

    case Library.create_library_board(board_params) do
      {:ok, _board} ->
        {:noreply,
         socket
         |> put_flash(:info, "Board created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
