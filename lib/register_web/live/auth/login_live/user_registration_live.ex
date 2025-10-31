defmodule RegisterWeb.Auth.LoginLive.UserRegistrationLive do
  use RegisterWeb, :live_view

  alias Register.Accounts
  alias Register.Accounts.User

  def render(assigns) do
    ~H"""
    <!-- Navigation -->
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
          <h2 class="text-3xl font-bold text-gray-900">Create your account</h2>
          <p class="mt-2 text-sm text-gray-600">Join SyncIn today</p>
        </div>

        <div class="bg-white py-8 px-6 shadow-xl rounded-xl">
          <.simple_form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            phx-trigger-action={@trigger_submit}
            action={~p"/users/login?_action=registered"}
            method="post"
            class="space-y-6"
          >
            <.error :if={@check_errors} class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
              Oops, something went wrong! Please check the errors below.
            </.error>

            <div class="space-y-5">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <.input
                  field={@form[:first_name]}
                  type="text"
                  label="First name"
                  required
                  placeholder="Enter your first name"
                />
                <.input
                  field={@form[:last_name]}
                  type="text"
                  label="Last name"
                  required
                  placeholder="Enter your last name"
                />
              </div>
              <div>
                <.input
                  field={@form[:email]}
                  type="email"
                  label="Email address"
                  required
                  class="appearance-none relative block w-full px-3 py-3 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm transition-all duration-200"
                  placeholder="Enter your email"
                />
              </div>

              <div class="relative">
                <.input
                  field={@form[:password]}
                  type={if @show_password, do: "text", else: "password"}
                  label="Password"
                  required
                  class="appearance-none relative block w-full px-3 py-3 pr-10 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm transition-all duration-200"
                  placeholder="Create a password"
                />
                <button
                  type="button"
                  phx-click="toggle_password"
                  class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600 transition-colors duration-200"
                  style="top: 24px;"
                >
                  <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <%= if @show_password do %>
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21" />
                    <% else %>
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    <% end %>
                  </svg>
                </button>
              </div>
            </div>

            <:actions>
              <.button
                phx-disable-with="Creating account..."
                class="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-medium rounded-lg text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98]"
              >
                <span class="absolute left-0 inset-y-0 flex items-center pl-3">
                  <svg class="h-5 w-5 text-blue-500 group-hover:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                  </svg>
                </span>
                Create Account
              </.button>
            </:actions>
          </.simple_form>

          <div class="mt-6 text-center">
            <p class="text-sm text-gray-600">
              Already have an account?
              <a href="/users/login" class="font-medium text-blue-600 hover:text-blue-500 transition-colors duration-200">
                Sign in here
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false, show_password: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("toggle_password", _params, socket) do
    {:noreply, assign(socket, show_password: !socket.assigns.show_password)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
