defmodule RegisterWeb.Admin.AdminsStaffLive.Index do
  use RegisterWeb, :live_view
  alias Register.Accounts
  alias RegisterWeb.Helpers.RoleHelper

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:sidebar_open, false)
      |> assign(:active_tab, "admin")
      |> assign(:users, [])

    if connected?(socket), do: send(self(), {:load_users, "admin"})
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = params["tab"] || "admin"
    if connected?(socket), do: send(self(), {:load_users, tab})
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_info({:load_users, tab}, socket) do
    users = Accounts.list_users_by_role(tab)
    {:noreply, assign(socket, :users, users)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("create_member", %{"email" => email, "phone" => _phone}, socket) do
    role = socket.assigns.active_tab
    case Accounts.create_user_with_role(%{email: email}, role) do
      {:ok, _user} ->
        send(self(), {:load_users, role})
        {:noreply, put_flash(socket, :info, "#{String.capitalize(role)} added successfully")}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add #{role}")}
      _ ->
        {:noreply, put_flash(socket, :error, "Failed to add #{role}")}
    end
  end

  @impl true
  def handle_event("remove_user", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    case Accounts.delete_user(user) do
      {:ok, _} ->
        send(self(), {:load_users, socket.assigns.active_tab})
        {:noreply, put_flash(socket, :info, "User removed")}
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove user")}
    end
  end
end
