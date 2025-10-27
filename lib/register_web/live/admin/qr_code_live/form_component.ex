defmodule RegisterWeb.Admin.QRCodeLive.FormComponent do
  use RegisterWeb, :live_component
  alias Phoenix.LiveView.JS
  alias Register.QrCodes

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:return_to, fn -> ~p"/Admin/qr_codes" end)
      |> assign_new(:current_user, fn -> assigns.current_user end)
      |> assign_new(:live_action, fn -> :new end)  # Default to :new if not provided

    form =
      case socket.assigns do
        %{live_action: :edit, qr_code: %QrCodes.QrCode{} = qr_code} ->
          qr_code
          |> QrCodes.change_qr_code()
          |> to_form(as: :qr_code)
        _ ->
          %QrCodes.QrCode{}
          |> QrCodes.change_qr_code(%{
            created_by_id: socket.assigns.current_user.id,
            is_active: true
          })
          |> to_form(as: :qr_code)
      end

    {:ok, assign(socket, :form, form)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id={@id} show={true} on_cancel={JS.navigate(@return_to)}>
        <div class="space-y-6">
          <div class="flex justify-between items-center">
            <h2 class="text-xl font-semibold text-gray-900">Generate QR Code</h2>
          </div>

          <.form
            for={@form}
            id="qr-code-form"
            phx-change="validate"
            phx-submit="save"
            phx-target={@myself}
            class="space-y-6"
          >
            <div>
              <.input field={@form[:name]} type="text" label="Name" required />
              <.error :for={error <- @form[:name].errors} class="mt-1 text-sm text-red-600">
                <%= error %>
              </.error>
            </div>

            <div>
              <.input field={@form[:description]} type="textarea" label="Description" />
              <.error :for={error <- @form[:description].errors} class="mt-1 text-sm text-red-600">
                <%= error %>
              </.error>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <.input field={@form[:class_name]} type="text" label="Class Name" required />
                <.error :for={error <- @form[:class_name].errors} class="mt-1 text-sm text-red-600">
                  <%= error %>
                </.error>
              </div>

              <div>
                <.input field={@form[:program_name]} type="text" label="Program Name" required />
                <.error :for={error <- @form[:program_name].errors} class="mt-1 text-sm text-red-600">
                  <%= error %>
                </.error>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <.input field={@form[:qr_data]} type="text" label="QR Data" required />
                <.error :for={error <- @form[:qr_data].errors} class="mt-1 text-sm text-red-600">
                  <%= error %>
                </.error>
              </div>

              <div class="hidden">
                <.input field={@form[:created_by_id]} type="hidden" value={@current_user.id} />
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <.input field={@form[:is_active]} type="checkbox" label="Active" />
                <.error :for={error <- @form[:is_active].errors} class="mt-1 text-sm text-red-600">
                  <%= error %>
                </.error>
              </div>

              <div>
                <.input field={@form[:expires_at]} type="datetime-local" label="Expires At" />
                <.error :for={error <- @form[:expires_at].errors} class="mt-1 text-sm text-red-600">
                  <%= error %>
                </.error>
              </div>
            </div>

            <div class="flex justify-end space-x-3 pt-4">
              <button
                type="button"
                phx-click={JS.navigate(@return_to)}
                class="bg-white py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Cancel
              </button>

              <button
                type="submit"
                class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                phx-disable-with="Saving..."
              >
                <%= if @live_action == :new, do: "Create", else: "Update" %> QR Code
              </button>
            </div>
          </.form>
        </div>
      </.modal>
    </div>
    """
  end

  @impl true

  def handle_event("validate", %{"qr_code" => params}, socket) do
    # Prepare params with user and required fields
    params_with_user =
      params
      |> Map.put("created_by_id", socket.assigns.current_user.id)
      |> Map.put_new_lazy("is_active", fn -> "true" end)

    # Generate QR data if not provided and we have required fields
    params_with_qr =
      if Map.get(params_with_user, "qr_data", "") == "" &&
         Map.get(params_with_user, "class_name", "") != "" &&
         Map.get(params_with_user, "program_name", "") != "" do
        qr_data = "#{params_with_user["class_name"]}_#{params_with_user["program_name"]}_#{System.system_time(:second)}"
        Map.put(params_with_user, "qr_data", qr_data)
      else
        params_with_user
      end

    changeset =
      case socket.assigns.live_action do
        :edit ->
          socket.assigns.qr_code
          |> QrCodes.change_qr_code(params_with_qr)
        _ ->
          %QrCodes.QrCode{}
          |> QrCodes.change_qr_code(params_with_qr)
      end
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :qr_code))}
  end

  def handle_event("save", %{"qr_code" => qr_code_params}, socket) do
    # Prepare params with user and required fields
    params_with_user =
      qr_code_params
      |> Map.put("created_by_id", socket.assigns.current_user.id)
      |> Map.put_new_lazy("is_active", fn -> "true" end)

    # Generate QR data if not provided and we have required fields
    params_with_qr =
      if Map.get(params_with_user, "qr_data", "") == "" &&
         Map.get(params_with_user, "class_name", "") != "" &&
         Map.get(params_with_user, "program_name", "") != "" do
        qr_data = "#{params_with_user["class_name"]}_#{params_with_user["program_name"]}_#{System.system_time(:second)}"
        Map.put(params_with_user, "qr_data", qr_data)
      else
        params_with_user
      end

    case socket.assigns.live_action do
      :new ->
        case Register.QrCodes.create_qr_code(params_with_qr) do
          {:ok, _qr_code} ->
            {:noreply,
             socket
             |> put_flash(:info, "QR Code created successfully")
             |> push_navigate(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, form: to_form(changeset, as: :qr_code))}
        end

      :edit ->
        case Register.QrCodes.update_qr_code(socket.assigns.qr_code, params_with_qr) do
          {:ok, _qr_code} ->
            {:noreply,
             socket
             |> put_flash(:info, "QR Code updated successfully")
             |> push_navigate(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, form: to_form(changeset, as: :qr_code))}
        end
    end
  end

  @impl true
  def handle_event("hide_form", _, socket) do
    {:noreply, push_navigate(socket, to: socket.assigns.return_to)}
  end
end
