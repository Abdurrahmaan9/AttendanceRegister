defmodule RegisterWeb.LibraryLive.Index do
  use RegisterWeb, :live_view

  alias Register.Library
  alias Register.Library.LibraryBoard

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:boards, Library.list_library_boards())
     |> assign(:search_query, "")
     |> assign(:active_tab, "invited")
     |> assign(:sidebar_open, false)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Online Library")
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:board, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add Resource")
    |> assign(:board, %LibraryBoard{})
  end

  defp apply_action(socket, :new_board, _params) do
    socket
    |> assign(:page_title, "Create Board")
    |> assign(:board, %LibraryBoard{})
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    # In a real app, filter boards based on query
    {:noreply, assign(socket, :search_query, query)}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end
end
