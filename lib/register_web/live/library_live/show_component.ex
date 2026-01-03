defmodule RegisterWeb.LibraryLive.ShowComponent do
  use RegisterWeb, :live_view

  alias Register.Library

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="p-6 bg-gray-50 min-h-screen">
        <div class="max-w-7xl mx-auto">
          <!-- Board Header -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden mb-6">
            <div class="relative h-48 bg-gray-100">
              <img
                src={@board.cover_image_url || "/images/default-board-cover.jpg"}
                alt={@board.title}
                class="w-full h-full object-cover"
              />
              <div class="absolute inset-0 bg-black bg-opacity-40 flex items-center justify-center">
                <div class="text-center text-white">
                  <h1 class="text-3xl font-bold mb-2">{@board.title}</h1>
                  <p class="text-lg opacity-90">{@board.subtitle || "Cavendish University Zambia"}</p>
                </div>
              </div>
            </div>

            <div class="p-6">
              <div class="flex items-center justify-between mb-4">
                <div class="flex items-center space-x-4 text-sm text-gray-500">
                  <span class="flex items-center space-x-1">
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                    </svg>
                    <span>{length(@board.resources)} resources</span>
                  </span>
                  <span class="flex items-center space-x-1">
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                    </svg>
                    <span>{@board.views_count} views</span>
                  </span>
                  <span class="flex items-center space-x-1">
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                    </svg>
                    <span>{@board.likes_count} likes</span>
                  </span>
                </div>

                <div class="flex items-center space-x-3">
                <%= if @current_user.role in ["admin", "lecturer"] do %>
                  <.link
                    patch={~p"/#{String.capitalize(String.replace(@current_user.role, "student", "students"))}/library/boards/#{@board.id}/new_resource"}
                    class="bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
                  >
                    Add Resource
                  </.link>
                <% end %>
                <.link
                  navigate={~p"/#{String.capitalize(String.replace(@current_user.role, "student", "students"))}/library"}
                  class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
                >
                  Back to Library
                </.link>
              </div>

              </div>

              <p class="text-gray-700">{@board.description}</p>
            </div>
          </div>

          <!-- Resources Section -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
            <div class="p-6 border-b border-gray-200">
              <h2 class="text-xl font-semibold text-gray-900">Resources</h2>
            </div>

            <div class="p-6">
              <%= if Enum.empty?(@board.resources) do %>
                <div class="text-center py-12">
                  <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
                  </svg>
                  <h3 class="mt-2 text-sm font-medium text-gray-900">No resources yet</h3>
                  <p class="mt-1 text-sm text-gray-500">
                    <%= if @current_user.role in ["admin", "lecturer"] do %>
                      Start by adding your first resource to this board.
                    <% else %>
                      No resources have been added to this board yet.
                    <% end %>
                  </p>
                </div>
              <% else %>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  <%= for resource <- @board.resources do %>
                    <div class="bg-gray-50 rounded-lg p-6 hover:bg-gray-100 transition-colors cursor-pointer border border-gray-200">
                      <div class="flex items-center mb-4">
                        <div class="p-2 bg-teal-100 rounded-lg">
                          <%= case resource.type do %>
                            <% "document" -> %>
                              <svg class="h-6 w-6 text-teal-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                              </svg>
                            <% "link" -> %>
                              <svg class="h-6 w-6 text-teal-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.826a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                              </svg>
                            <% "video" -> %>
                              <svg class="h-6 w-6 text-teal-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                              </svg>
                            <% _ -> %>
                              <svg class="h-6 w-6 text-teal-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                              </svg>
                          <% end %>
                        </div>
                        <div class="ml-3">
                          <span class="text-xs font-medium text-gray-500 uppercase">{resource.type}</span>
                        </div>
                      </div>

                      <h3 class="font-semibold text-gray-900 mb-2">{resource.name}</h3>
                      <p class="text-sm text-gray-600 mb-4 line-clamp-2">{resource.description}</p>

                      <div class="flex items-center justify-between">
                        <span class="text-xs text-gray-500">
                          Added {Calendar.strftime(resource.inserted_at, "%d %b %Y")}
                        </span>
                        <div class="flex items-center space-x-2">
                          <%= cond do %>
                            <% resource.external_url -> %>
                              <a
                                href={resource.external_url}
                                target="_blank"
                                class="text-teal-600 hover:text-teal-700 text-sm font-medium"
                              >
                                Open
                              </a>
                            <% resource.file_url -> %>
                              <a
                                href={resource.file_url}
                                target="_blank"
                                class="text-teal-600 hover:text-teal-700 text-sm font-medium"
                              >
                                Open
                              </a>
                            <% true -> %>
                              <span class="text-gray-400 text-sm font-medium">
                                No URL available
                              </span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <%= if @live_action == :new_resource do %>
        <.modal id="resource-modal" show on_cancel={JS.patch(~p"/#{String.capitalize(String.replace(@current_user.role, "student", "students"))}/library/boards/#{@board.id}")}>
          <.live_component
            module={RegisterWeb.LibraryLive.FormComponent}
            id={:new_resource}
            title="Add Resource"
            action={:new}
            board={@board}
            current_user={@current_user}
            patch={~p"/#{String.capitalize(String.replace(@current_user.role, "student", "students"))}/library/boards/#{@board.id}"}
          />
        </.modal>
      <% end %>

    """
  end
  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    board = Library.get_library_board!(id)

    {:noreply,
     socket
     |> assign(:board, board)
     |> assign(:page_title, board.title)
     |> apply_action(socket.assigns.live_action)}
  end

  defp apply_action(socket, :new_resource) do
    socket
    |> assign(:resource, %Library.LibraryResource{board_id: socket.assigns.board.id})
  end

  defp apply_action(socket, _), do: assign(socket, :resource, nil)

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end
end
