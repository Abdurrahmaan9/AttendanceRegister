defmodule RegisterWeb.LibraryLive.FormComponent do
  use RegisterWeb, :live_component

  alias Register.Library

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-center space-x-6 overflow-x-auto pb-4 border-b border-gray-100 mb-6">
        <%= for {type, icon, label} <- [
          {"document", "M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z", "Document"},
          {"link", "M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.826a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1", "Link"},
          {"album", "M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z", "Album"},
          {"video", "M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z", "Video"},
          {"embedded", "M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4", "Embedded"},
          {"assessment", "M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01", "Assessment"}
        ] do %>
          <button phx-click="select_type" phx-value-type={type} phx-target={@myself} class={"flex flex-col items-center space-y-2 group " <> if(@type == type, do: "text-blue-600", else: "text-gray-400 hover:text-gray-600")}>
            <div class={"p-2 rounded-lg " <> if(@type == type, do: "bg-blue-50", else: "bg-gray-50 group-hover:bg-gray-100")}>
              <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={icon} />
              </svg>
            </div>
            <span class="text-[10px] font-medium uppercase tracking-wider">{label}</span>
          </button>
        <% end %>
      </div>

      <h2 class="text-lg font-semibold text-gray-900 mb-6">Add {@type}</h2>

      <.form
        for={@form}
        id="library-resource-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <.input field={@form[:type]} type="hidden" value={@type} />
        <div class="space-y-4">
          <label class="block text-sm font-medium text-gray-700">
            Upload or give a link to a PDF, PowerPoint, Word or Excel document.
          </label>
          <div class="flex flex-col space-y-4">
            <div class="flex items-center space-x-4">
              <div
                id="file-upload"
                phx-drop-zone={@uploads.file.ref}
                phx-hook="FileUpload"
                class="relative"
              >
                <input
                  type="file"
                  id="file-input"
                  name={@uploads.file.name}
                  accept={@uploads.file.accept}
                  multiple={@uploads.file.max_entries > 1}
                  phx-target={@myself}
                  phx-change="validate"
                  class="hidden"
                />
                <button type="button" phx-click={JS.dispatch("click", to: "#file-input")} class="bg-teal-600 text-white px-4 py-2 rounded text-sm font-medium hover:bg-teal-700">
                  Choose files
                </button>
              </div>
              <%= for entry <- @uploads.file.entries do %>
                <span class="text-sm text-gray-600">{entry.name}</span>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  phx-target={@myself}
                  class="text-red-500 hover:text-red-700 text-sm"
                >
                  Cancel
                </button>
              <% end %>
            </div>
            <div class="relative">
              <div class="absolute inset-0 flex items-center" aria-hidden="true">
                <div class="w-full border-t border-gray-200"></div>
              </div>
              <div class="relative flex justify-center text-sm">
                <span class="px-2 bg-white text-gray-500 uppercase">OR</span>
              </div>
            </div>
            <input
              type="text"
              name="external_url"
              placeholder="Paste URL to document"
              class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-teal-500 focus:border-teal-500 sm:text-sm"
            />
          </div>
        </div>

        <div>
          <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
            GIVE YOUR RESOURCE A NAME
          </label>
          <.input field={@form[:name]} type="text" placeholder="Name of the resource" class="w-full" />
        </div>

        <div>
          <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
            DESCRIBE YOUR RESOURCE
          </label>
          <.input field={@form[:description]} type="textarea" placeholder="Describe the resource you are about to add" class="w-full h-32" />
        </div>

        <div class="space-y-3">
          <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
            SETTINGS
          </label>
          <div class="space-y-2">
            <%= for {key, label} <- [
              {"show_info", "Show content info when it's opened"},
              {"allow_download", "Allow downloading this content"},
              {"comments_allowed", "Comments allowed"},
              {"show_comments_default", "Show comments by default"}
            ] do %>
              <label class="flex items-center space-x-3">
                <input type="checkbox" name={"settings[#{key}]"} class="h-4 w-4 text-teal-600 border-gray-300 rounded focus:ring-teal-500" />
                <span class="text-sm text-gray-600">{label}</span>
              </label>
            <% end %>
          </div>
        </div>

        <div>
          <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
            ADD CONTENT COVER PICTURE
          </label>
          <div class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md hover:border-teal-400 transition-colors">
            <div class="space-y-1 text-center">
              <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48" aria-hidden="true">
                <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
              <div class="flex text-sm text-gray-600">
                <button type="button" phx-click={JS.dispatch("click", to: "#cover-upload")} class="relative cursor-pointer bg-white rounded-md font-medium text-teal-600 hover:text-teal-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-teal-500">
                  <span>Upload a file</span>
                </button>
                <p class="pl-1">or drag and drop</p>
              </div>
              <p class="text-xs text-gray-500">
                Default image will be used if you don't upload your own image.
              </p>
            </div>
          </div>
          <input
            type="file"
            id="cover-upload"
            name="cover_upload"
            accept="image/*"
            class="hidden"
            phx-target={@myself}
            phx-change="cover_selected"
          />
        </div>

        <div class="border-t border-gray-100 pt-6">
          <button type="button" phx-click={JS.toggle(to: "#advanced-settings")} class="flex items-center justify-between w-full text-sm text-gray-500 hover:text-gray-700">
            <span>Advanced settings</span>
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          <div id="advanced-settings" class="hidden mt-6 space-y-6">
            <div>
              <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
                ADD DESCRIPTIVE TAGS
              </label>
              <select class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-teal-500 focus:border-teal-500 sm:text-sm">
                <option>Add a tag to article</option>
              </select>
            </div>

            <div class="space-y-4">
              <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
                ADD ANALYTICS LABELS
              </label>
              <div class="flex space-x-2">
                <input type="text" placeholder="Add a label" class="flex-1 border-gray-300 rounded-md shadow-sm focus:ring-teal-500 focus:border-teal-500 sm:text-sm" />
                <input type="text" placeholder="Add a value" class="flex-1 border-gray-300 rounded-md shadow-sm focus:ring-teal-500 focus:border-teal-500 sm:text-sm" />
                <button type="button" class="bg-teal-600 text-white px-4 py-2 rounded text-sm font-medium hover:bg-teal-700">Add</button>
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
                  AVAILABLE FROM
                </label>
                <input type="date" class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-teal-500 focus:border-teal-500 sm:text-sm" />
              </div>
              <div>
                <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
                  TO
                </label>
                <input type="date" class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-teal-500 focus:border-teal-500 sm:text-sm" />
              </div>
            </div>
          </div>
        </div>

        <div class="flex justify-end pt-6">
          <.button phx-disable-with="Saving...">Save Resource</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{board: board} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> allow_upload(:file, accept: ~w(.pdf .doc .docx .ppt .pptx .xls .xlsx), max_file_size: 5_000_000)
      |> assign(:type, "document")
      |> assign_form(Library.change_library_resource(%Library.LibraryResource{board_id: board.id}))

    {:ok, socket}
  end

  @impl true
  def handle_event("select_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :type, type)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  def handle_event("file_selected", %{"_target" => ["file_input"], "file_input" => %{} = file_params}, socket) do
    # For now, we'll just store the file name - in a real app you'd upload to cloud storage
    file_url = "/uploads/#{file_params.name}"

    changeset =
      socket.assigns.form
      |> Ecto.Changeset.change(%{file_url: file_url, name: file_params.name})

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("file_selected", %{"_target" => ["file_input"]}, socket) do
    # No file selected
    {:noreply, socket}
  end

  def handle_event("cover_selected", %{"_target" => ["cover_upload"], "cover_upload" => %{} = cover_params}, socket) do
    # Handle cover image selection
    cover_url = "/uploads/covers/#{cover_params.name}"

    changeset =
      socket.assigns.form
      |> Ecto.Changeset.change(%{cover_image_url: cover_url})

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("cover_selected", %{"_target" => ["cover_upload"]}, socket) do
    # No cover selected
    {:noreply, socket}
  end

  def handle_event("validate", %{"_target" => ["file"]}, socket) do
    # Handle file upload validation
    {:noreply, socket}
  end

  def handle_event("validate", %{"library_resource" => resource_params}, socket) do
    resource_params = Map.put(resource_params, "type", socket.assigns.type)
    changeset =
      %Library.LibraryResource{}
      |> Library.change_library_resource(resource_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"library_resource" => resource_params}, socket) do
    save_resource(socket, socket.assigns.action, resource_params)
  end

  defp save_resource(socket, :new, resource_params) do
    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{path: _path}, entry ->
        {:ok, "/uploads/#{entry.name}"}
      end)

    resource_params =
      case uploaded_files do
        [file_url | _] ->
          Map.put(resource_params, "file_url", file_url)

        [] ->
          resource_params
      end

    resource_params =
      case Map.get(resource_params, "external_url") do
        "" -> resource_params
        nil -> resource_params
        url -> Map.put(resource_params, "external_url", url)
      end

    resource_params =
      case Map.get(resource_params, "settings") do
        settings when is_map(settings) ->
          Map.put(resource_params, "settings", settings)

        _ ->
          resource_params
      end

    resource_params =
      resource_params
      |> Map.put("board_id", socket.assigns.board.id)
      |> Map.put("created_by_id", socket.assigns.current_user.id)

    case Library.create_library_resource(resource_params) do
      {:ok, _resource} ->
        {:noreply,
        socket
        |> put_flash(:info, "Resource added successfully")
        |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end


  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
