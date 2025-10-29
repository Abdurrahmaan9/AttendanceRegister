defmodule RegisterWeb.Auth.UserForgotPasswordLive do
  use RegisterWeb, :live_view

  alias Register.Accounts

  def render(assigns) do
    ~H"""
    <nav class="bg-white shadow-sm fixed top-0 left-0 right-0 z-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center">
          <a href="/" class="flex items-center space-x-2">
            <img
              src={~p"/logo/syncin-high-resolution-logo-grayscale-transparent.png"}
              alt="SyncIn logo"
              class="h-6 w-auto"
            />
            <!--<span class="text-2xl font-bold text-blue-600 whitespace-nowrap">SyncIn</span>-->
          </a>
          </div>
            <div class="flex items-center space-x-8">
              <a href="/" class="text-gray-700 hover:text-blue-600 px-3 py-2 text-sm font-medium">Home</a>
              <a href="/about" class="text-gray-700 hover:text-blue-600 px-3 py-2 text-sm font-medium">About</a>
            </div>
        </div>
      </div>
    </nav>

    <div class="pt-24;">
      <div class="max-w-md w-full space-y-8">
        <div class="text-center">
          <div class="mx-auto h-16 w-16 bg-blue-600 rounded-full flex items-center justify-center mb-4">
            <svg class="h-8 w-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 0112 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
            </svg>
          </div>
        </div>

        <div class="bg-white py-8 px-6 shadow-xl rounded-xl">
          <.header class="text-center">
            Forgot your password?
            <:subtitle>We'll send a password reset link to your inbox</:subtitle>
          </.header>

          <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
            <.input field={@form[:email]} type="email" placeholder="Email" required />
            <:actions>
              <.button phx-disable-with="Sending..." class="w-full">
                Send password reset instructions
              </.button>
            </:actions>
          </.simple_form>
          <p class="text-center text-sm mt-4">
            <.link href={~p"/users/register"}>Register</.link>
            | <.link href={~p"/users/login"}>Log in</.link>
          </p>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
