defmodule RegisterWeb.Auth.LoginLive do
  use RegisterWeb, :live_view

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form, show_password: false), temporary_assigns: [form: form]}
  end

  def handle_event("toggle_password", _params, socket) do
    {:noreply, assign(socket, show_password: !socket.assigns.show_password)}
  end
end
