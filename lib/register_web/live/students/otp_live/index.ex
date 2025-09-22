defmodule RegisterWeb.Students.OtpLive.Index do
  use RegisterWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, sidebar_open: false)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "OTP Verification")
    |> assign(:otp, nil)
  end

  defp apply_action(socket, :show, %{"id" => _id}) do
    socket
    |> assign(:page_title, "View OTP")
  end

  defp apply_action(socket, :verify, %{"id" => _id}) do
    socket
    |> assign(:page_title, "Verify OTP")
  end

  # @impl true
  # def handle_event("verify_otp", %{"otp" => otp}, socket) do
  #   # OTP verification logic here
  #   {:noreply, socket}
  # end
end
