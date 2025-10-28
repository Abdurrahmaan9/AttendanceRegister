defmodule RegisterWeb.Admin.UserMgtLive.Index do
  use RegisterWeb, :live_view
  alias Register.Accounts
  alias RegisterWeb.Helpers.RoleHelper

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
    |> assign(users: [])
    |> assign(:sidebar_open, false)

    if connected?(socket), do: send(self(), {:load_users, "all"})
    {:ok, assign(socket, active_tab: "all")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = params["tab"] || "all"
    if connected?(socket), do: send(self(), {:load_users, tab})
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_info({:load_users, tab}, socket) do
    users =
      case tab do
        "all" -> Accounts.list_users()
        role -> Accounts.list_users_by_role(role)
      end
    {:noreply, assign(socket, :users, users)}
  end

  @impl true
  def handle_event("update_role", %{"user_id" => user_id, "role" => role}, socket) do
    user = Accounts.get_user!(user_id)
    case Accounts.assign_role(user, role) do
      {:ok, _user} ->
        send(self(), {:load_users, socket.assigns.active_tab})
        {:noreply, put_flash(socket, :info, "User role updated successfully")}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update user role")}
    end
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end
end
