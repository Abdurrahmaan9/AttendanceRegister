defmodule RegisterWeb.Admin.OTPManagementLive.FormComponent do
  use RegisterWeb, :live_component

  alias Phoenix.LiveView.JS
  alias Register.Otps
  alias Register.Otps.Otp

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:return_to, fn -> ~p"/Admin/otp-management" end)
      |> assign_new(:current_user, fn -> assigns.current_user end)
      |> assign_new(:live_action, fn -> :new end)  # Default to :new if not provided

    page_title = if socket.assigns.live_action == :edit, do: "Edit OTP", else: "New OTP"
    socket = assign(socket, :page_title, page_title)

    form =
      case socket.assigns do
        %{live_action: :edit, otp: %Otp{} = otp} ->
          otp
          |> Otps.change_otp()
          |> to_form(as: :otp)
        _ ->
          %Otp{
            created_by_id: socket.assigns.current_user.id,
            is_active: true
          }
          |> Otps.change_otp()
          |> to_form(as: :otp)
      end

    {:ok, assign(socket, :form, form)}
  end

  defp format_datetime_for_input(%NaiveDateTime{} = datetime) do
    datetime
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.to_string()
    |> String.replace(" ", "T")
    |> String.replace(":00.000000", "")
  end

  defp process_params(params) do
    # Ensure we have a map with string keys
    params = Map.new(params, fn {k, v} -> {to_string(k), v} end)

    # Set default values for required fields
    params =
      params
      |> Map.put_new("is_active", "false")
      |> Map.put_new("purpose", "authentication")
      |> Map.put_new("metadata", "{}")

    # Process is_active checkbox
    params =
      if Map.has_key?(params, "is_active") do
        Map.put(params, "is_active", params["is_active"] == "on")
      else
        Map.put(params, "is_active", false)
      end

    # Process metadata
    params =
      case params["metadata"] do
        "" -> Map.put(params, "metadata", %{})
        json when is_binary(json) ->
          case Jason.decode(json) do
            {:ok, decoded} when is_map(decoded) -> Map.put(params, "metadata", decoded)
            _ -> Map.put(params, "metadata", %{})
          end
        map when is_map(map) -> Map.put(params, "metadata", map)
        _ -> Map.put(params, "metadata", %{})
      end

    # Process expires_at
    params =
      case params["expires_at"] do
        %NaiveDateTime{} = dt ->
          Map.put(params, "expires_at", dt)
        "" ->
          # Set default expiration to 30 minutes from now if not provided
          Map.put(params, "expires_at", NaiveDateTime.add(NaiveDateTime.utc_now(), 30 * 60))
        datetime_str when is_binary(datetime_str) ->
          case NaiveDateTime.from_iso8601("#{datetime_str}:00") do
            {:ok, datetime} -> Map.put(params, "expires_at", datetime)
            _ -> Map.put(params, "expires_at", NaiveDateTime.add(NaiveDateTime.utc_now(), 30 * 60))
          end
        _ ->
          Map.put(params, "expires_at", NaiveDateTime.add(NaiveDateTime.utc_now(), 30 * 60))
      end

    params
  end

  @impl true
  def handle_event("validate", %{"otp" => params}, socket) do
    # Prepare params with user and default values
    params_with_user =
      params
      |> process_params()
      |> Map.put("created_by_id", socket.assigns.current_user.id)

    changeset =
      case socket.assigns.live_action do
        :edit ->
          socket.assigns.otp
          |> Otps.change_otp(params_with_user)
        _ ->
          %Otp{}
          |> Otps.change_otp(params_with_user)
      end
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :otp))}
  end

  @impl true
  def handle_event("save", %{"otp" => params}, socket) do
    # Prepare params with user and default values
    params_with_user =
      params
      |> process_params()
      |> Map.put("created_by_id", socket.assigns.current_user.id)

    # Generate a code if not provided
    params_with_code =
      if Map.get(params_with_user, "code", "") == "" do
        Map.put(params_with_user, "code", Register.Otps.Otp.generate_code())
      else
        params_with_user
      end
      # Ensure code is exactly 6 characters
      |> Map.update!("code", &String.slice(&1, 0..5))

    # Log the params for debugging
    IO.inspect(params_with_code, label: "Saving OTP with params")

    result =
      case socket.assigns.live_action do
        :new ->
          Otps.create_otp(params_with_code)
        :edit ->
          Otps.update_otp(socket.assigns.otp, params_with_code)
      end

    case result do
      {:ok, otp} ->
        IO.inspect(otp, label: "Successfully saved OTP")
        {:noreply,
         socket
         |> put_flash(:info, "OTP #{socket.assigns.live_action == :new && "created" || "updated"} successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset, label: "Error saving OTP")
        {:noreply, assign(socket, form: to_form(changeset, as: :otp))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex justify-between items-center">
        <h2 class="text-xl font-semibold text-gray-900"><%= @page_title %></h2>
      </div>

          <.form
            for={@form}
            id="otp-form"
            phx-change="validate"
            phx-submit="save"
            phx-target={@myself}
            class="space-y-6"
          >
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <div class="space-y-2">
                  <label for="otp_code" class="block text-sm font-medium text-gray-700">
                    Code
                    <span class="text-xs text-gray-500">(leave empty to auto-generate)</span>
                  </label>
                  <div class="mt-1">
                    <input
                      type="text"
                      id={@form[:code].id}
                      name={@form[:code].name}
                      value={@form[:code].value || ""}
                      placeholder="Leave empty to auto-generate"
                      class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                      readonly={@live_action == :edit}
                    />
                    <%= for {error, _opts} <- @form[:code].errors do %>
                      <p class="mt-1 text-sm text-red-600"><%= error %></p>
                    <% end %>
                  </div>
                </div>
              </div>

              <div>
                <div class="space-y-2">
                  <label for="otp_purpose" class="block text-sm font-medium text-gray-700">
                    Purpose
                  </label>
                  <div class="mt-1">
                    <select
                      id={@form[:purpose].id}
                      name={@form[:purpose].name}
                      class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                      required
                    >
                      <option value="">Select a purpose</option>
                      <option value="authentication" selected={@form[:purpose].value == "authentication"}>Authentication</option>
                      <option value="verification" selected={@form[:purpose].value == "verification"}>Verification</option>
                      <option value="password_reset" selected={@form[:purpose].value == "password_reset"}>Password Reset</option>
                      <option value="other" selected={@form[:purpose].value == "other"}>Other</option>
                    </select>
                    <%= for {error, _opts} <- @form[:purpose].errors do %>
                      <p class="mt-1 text-sm text-red-600"><%= error %></p>
                    <% end %>
                  </div>
                </div>
              </div>

              <div>
                <div class="space-y-2">
                  <label for="otp_expires_at" class="block text-sm font-medium text-gray-700">
                    Expires At
                  </label>
                  <div class="mt-1">
                    <input
                      type="datetime-local"
                      id={@form[:expires_at].id}
                      name={@form[:expires_at].name}
                      value={case @form[:expires_at].value do
                        %DateTime{} = dt ->
                          dt
                          |> DateTime.truncate(:second)
                          |> DateTime.to_naive()
                          |> format_datetime_for_input()
                        %NaiveDateTime{} = ndt ->
                          ndt
                          |> NaiveDateTime.truncate(:second)
                          |> format_datetime_for_input()
                        _ -> ""
                      end}
                      class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                      required
                    />
                    <%= for {error, _opts} <- @form[:expires_at].errors do %>
                      <p class="mt-1 text-sm text-red-600"><%= error %></p>
                    <% end %>
                  </div>
                </div>
              </div>

              <div class="flex items-center space-x-2 pt-6">
                <input
                  type="checkbox"
                  id={@form[:is_active].id}
                  name={@form[:is_active].name}
                  checked={@form[:is_active].value}
                  class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
                <label for={@form[:is_active].id} class="text-sm font-medium text-gray-700">
                  Active
                </label>
              </div>

              <div class="col-span-2">
                <div class="space-y-2">
                  <label for="otp_metadata" class="block text-sm font-medium text-gray-700">
                    Metadata (JSON)
                  </label>
                  <div class="mt-1">
                    <textarea
                      id={@form[:metadata].id}
                      name={@form[:metadata].name}
                      class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm font-mono"
                      rows="4"
                      placeholder='{"key": "value"}'
                    ><%= if is_map(@form[:metadata].value), do: Jason.encode!(@form[:metadata].value), else: @form[:metadata].value %></textarea>
                    <%= for {error, _opts} <- @form[:metadata].errors do %>
                      <p class="mt-1 text-sm text-red-600"><%= error %></p>
                    <% end %>
                  </div>
                  <p class="text-xs text-gray-500">
                    Optional JSON metadata for additional data (e.g., key-value pairs)
                  </p>
                </div>
              </div>
            </div>

            <div class="flex justify-end space-x-3 pt-4">
              <.button
                type="button"
                variant={:secondary}
                phx-click={JS.navigate(@return_to)}
              >
                Cancel
              </.button>

              <.button
                type="submit"
                variant={:primary}
                phx-disable-with="Saving..."
              >
                <%= if @live_action == :new, do: "Create", else: "Update" %> OTP
              </.button>
            </div>
      </.form>
    </div>
    """
  end
end
