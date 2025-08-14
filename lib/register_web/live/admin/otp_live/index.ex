defmodule RegisterWeb.Admin.OtpLive.Index do
  use RegisterWeb, :live_view
  alias Register.Accounts
  alias RegisterWeb.Helpers.RoleHelper

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:active_tab, "all")
      |> load_users("all")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = params["tab"] || "all"
    {:noreply, assign(socket, :active_tab, tab) |> load_users(tab)}
  end

  defp load_users(socket, "all"), do: assign(socket, :users, Accounts.list_users())
  defp load_users(socket, role), do: assign(socket, :users, Accounts.list_users_by_role(role))

  @impl true
  def handle_event("update_role", %{"user_id" => user_id, "role" => role}, socket) do
    user = Accounts.get_user!(user_id)
    case Accounts.assign_role(user, role) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User role updated successfully")
         |> load_users(socket.assigns.active_tab)}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update user role")}
    end
  end
end
