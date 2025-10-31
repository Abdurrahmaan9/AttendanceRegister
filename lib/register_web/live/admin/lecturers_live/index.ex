defmodule RegisterWeb.Admin.LecturersLive.Index do
  use RegisterWeb, :live_view
  alias Register.Accounts
  alias RegisterWeb.Helpers.RoleHelper

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:sidebar_open, false)
      |> assign(:lecturers, [])

    if connected?(socket), do: send(self(), :load)
    {:ok, socket}
  end

  @impl true
  def handle_info(:load, socket) do
    lecturers = Accounts.list_users_by_role("lecturer")
    {:noreply, assign(socket, :lecturers, lecturers)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("create_lecturer", %{"email" => email, "first_name" => first_name, "last_name" => last_name, "phone" => _phone}, socket) do
    # Password is auto-generated and emailed; phone is currently unused
    case Accounts.create_user_with_role(%{email: email, first_name: first_name, last_name: last_name}, "lecturer") do
      {:ok, _user} ->
        send(self(), :load)
        {:noreply, put_flash(socket, :info, "Lecturer added successfully")}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add lecturer")}
      _ ->
        {:noreply, put_flash(socket, :error, "Failed to add lecturer")}
    end
  end

  @impl true
  def handle_event("remove_user", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    case Accounts.delete_user(user) do
      {:ok, _} ->
        send(self(), :load)
        {:noreply, put_flash(socket, :info, "Lecturer removed")}
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove lecturer")}
    end
  end
end
