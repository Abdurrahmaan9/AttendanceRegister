defmodule RegisterWeb.Admin.QrCodeLive.ShowComponent do
  use RegisterWeb, :live_view
  alias Register.QrCodes
  alias QRCode.Render.SvgSettings
  alias EQRCode

  
  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    qr_code = QrCodes.get_qr_code!(id)

    {:noreply,
     socket
     |> assign(:page_title, "QR Code: #{qr_code.name}")
     |> assign(:qr_code, qr_code)
     |> assign(:qr_svg, generate_qr_svg(qr_code.qr_data))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-8">
      <div class="text-center">
        <h1 class="text-2xl font-bold text-gray-900 mb-2">QR Code: <%= @qr_code.name %></h1>
        <p class="text-gray-600 mb-8">
          Point your device's camera at this code to scan it
        </p>

        <div class="bg-white p-6 rounded-lg shadow-md inline-block">
        <div class="flex justify-center mb-6" style="min-height: 300px; min-width: 300px;">
          <%= if is_binary(@qr_svg) do %>
            <div id={"qr-code-#{@qr_code.id}"} class="w-full h-full">
              <%= Phoenix.HTML.raw(@qr_svg) %>
            </div>
          <% else %>
            <div class="text-red-500 flex items-center">
              Error: Could not generate QR code image
            </div>
          <% end %>
        </div>

          <div class="mt-6 text-sm text-gray-600">
            <p class="font-medium">Details:</p>
            <p>Name: <%= @qr_code.name %></p>
            <%= if @qr_code.description do %>
              <p>Description: <%= @qr_code.description %></p>
            <% end %>
            <p>Class: <%= @qr_code.class_name %></p>
            <p>Program: <%= @qr_code.program_name %></p>
            <p>Status:
              <span class={
                ["inline-flex rounded-full px-2 text-xs font-semibold leading-5",
                 if(@qr_code.is_active, do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800")]
              }>
                <%= if @qr_code.is_active, do: "Active", else: "Inactive" %>
              </span>
            </p>
            <%= if @qr_code.expires_at do %>
              <p>Expires: <%= Calendar.strftime(@qr_code.expires_at, "%Y-%m-%d %H:%M") %></p>
            <% end %>
          </div>
        </div>

        <div class="mt-8">
          <p class="text-sm text-gray-500">
            Can't scan? Enter this code: <span class="font-mono bg-gray-100 px-2 py-1 rounded"><%= @qr_code.qr_data %></span>
          </p>

          <div class="mt-6">
            <.link
              patch={~p"/Admin/qr-codes"}
              class="text-blue-600 hover:text-blue-800 font-medium"
            >
              ← Back to QR Codes
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp generate_qr_svg(data) do
    data
    |> to_string()
    |> EQRCode.encode()
    |> case do
      {:ok, qr_code} -> EQRCode.svg(qr_code, width: 300)
      _ -> nil
    end
  end
end
