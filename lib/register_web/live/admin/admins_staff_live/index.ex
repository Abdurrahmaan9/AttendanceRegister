defmodule RegisterWeb.Admin.AdminsStaffLive.Index do
  use RegisterWeb, :live_view
  import RegisterWeb.Utils

  alias Register.Accounts
  alias RegisterWeb.Helpers.RoleHelper

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:sidebar_open, false)
      |> assign(:active_tab, "admin")
      |> assign(:users, [])
      |> assign(:loading, true)

    if connected?(socket), do: send(self(), {:load_users, "admin"})
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = params["tab"] || "admin"
    send(self(), {:load_users, tab})
    {:noreply, socket |> assign(:active_tab, tab) |> assign(:loading, true)}
  end

  @impl true
  def handle_info({:load_users, tab}, socket) do
    users = Accounts.list_users_by_role(tab)
    {:noreply, socket |> assign(:users, users) |> assign(:loading, false)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("create_member", %{"email" => email, "first_name" => first_name, "last_name" => last_name, "phone" => _phone}, socket) do
    role = socket.assigns.active_tab
    case Accounts.create_user_with_role(%{email: email, first_name: first_name, last_name: last_name}, role) do
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
