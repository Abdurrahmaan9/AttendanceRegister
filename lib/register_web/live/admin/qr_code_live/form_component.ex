defmodule RegisterWeb.Admin.QRCodeLive.FormComponent do
  use RegisterWeb, :live_component
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-xl font-semibold text-gray-900">Generate QR Code</h2>
      <button
        phx-click={JS.push("hide_form", target: @myself)}
        class="text-gray-400 hover:text-gray-600 transition-colors"
      >
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </button>
    </div>

    <.form
      for={@form}
      id="qr-code-form"
      phx-change="validate"
      phx-submit="save"
      phx-target={@myself}
      class="space-y-6"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <.input
            field={@form[:name]}
            type="text"
            label="Module Code"
            placeholder="Enter module code"
            required
          />
        </div>
        <div>
          <.input
            field={@form[:class_name]}
            type="text"
            label="Class Name"
            placeholder="e.g., Auditing101"
            required
          />
        </div>
        <div>
          <.input
            field={@form[:program_name]}
            type="text"
            label="Program Name"
            placeholder="e.g., Banking and Finance"
            required
          />
        </div>
        <div>
          <.input
            field={@form[:expires_at]}
            type="datetime-local"
            label="Expiration Date (Optional)"
          />
        </div>
      </div>

      <div>
        <.input
          field={@form[:description]}
          type="textarea"
          label="Description (Optional)"
          placeholder="Additional details about this QR code"
          rows="3"
        />
      </div>

      <div class="flex space-x-4">
        <button
          type="button"
          phx-click="generate_qr"
          phx-target={@myself}
          class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors flex items-center"
        >
          <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"></path>
          </svg>
          Generate QR Code
        </button>
        <button
          :if={@qr_svg}
          type="submit"
          class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors flex items-center"
        >
          <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
          Save QR Code
        </button>
      </div>
    </.form>
    """
  end

  @impl true
  def handle_event("validate", %{"form" => form_params}, socket) do
    # Handle form validation
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"form" => form_params}, socket) do
    # Handle form submission
    {:noreply, socket}
  end

  @impl true
  def handle_event("generate_qr", _, socket) do
    # Handle QR code generation
    {:noreply, socket}
  end

  @impl true
  def handle_event("hide_form", _, socket) do
    # Handle hiding the form
    send(self(), {:hide_form})
    {:noreply, socket}
  end
end
