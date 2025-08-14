defmodule RegisterWeb.Admin.QrCodeLive.Index do
  use RegisterWeb, :live_view

  alias Register.QrCodes
  alias Register.QrCodes.QrCode

  @url "/Admin/qr_codes"
  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_path, @url)
     |> assign(:qr_codes, list_qr_codes())
     |> assign(:form, to_form(QrCodes.change_qr_code(%QrCode{})))
     |> assign(:show_form, false)
     |> assign(:generated_qr_code, nil)
     |> assign(:qr_svg, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "QR Code Management")
    |> assign(:qr_code, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Generate New QR Code")
    |> assign(:qr_code, %QrCode{})
    |> assign(:show_form, true)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit QR Code")
    |> assign(:qr_code, QrCodes.get_qr_code!(id))
    |> assign(:show_form, true)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    qr_code = QrCodes.get_qr_code!(id)
    {:ok, _} = QrCodes.delete_qr_code(qr_code)

    {:noreply, assign(socket, :qr_codes, list_qr_codes())}
  end

  def handle_event("toggle_active", %{"id" => id}, socket) do
    qr_code = QrCodes.get_qr_code!(id)
    {:ok, _} = QrCodes.update_qr_code(qr_code, %{is_active: !qr_code.is_active})

    {:noreply, assign(socket, :qr_codes, list_qr_codes())}
  end

  def handle_event("validate", %{"qr_code" => qr_code_params}, socket) do
    qr_code = socket.assigns.qr_code || %QrCode{}

    changeset =
      qr_code
      |> QrCodes.change_qr_code(qr_code_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"qr_code" => qr_code_params}, socket) do
    save_qr_code(socket, socket.assigns.live_action, qr_code_params)
  end

  def handle_event("generate_qr", _params, socket) do
    # Get form data from socket assigns
    form_params = socket.assigns.form.params
    class_name = form_params["class_name"] || ""
    program_name = form_params["program_name"] || ""

    # Generate QR data
    qr_data = QrCodes.generate_qr_data(class_name, program_name)

    # Generate QR code SVG
    qr_svg =
      case QRCode.create(qr_data) do
        {:ok, qr_code} ->
          case QRCode.render(qr_code) do
            {:ok, svg_string} ->
              IO.inspect(svg_string, label: "Generated SVG")
              svg_string
            {:error, reason} ->
              IO.inspect(reason, label: "SVG Render Error")
              nil
          end
        {:error, reason} ->
          IO.inspect(reason, label: "QR Create Error")
          nil
        qr_code when is_struct(qr_code) ->
          # Handle case where QRCode.create returns struct directly
          case QRCode.render(qr_code) do
            {:ok, svg_string} ->
              IO.inspect(svg_string, label: "Generated SVG (direct)")
              svg_string
            {:error, reason} ->
              IO.inspect(reason, label: "SVG Render Error (direct)")
              nil
            svg_string when is_binary(svg_string) ->
              IO.inspect(svg_string, label: "Generated SVG (binary)")
              svg_string
          end
      end

    IO.inspect(qr_svg, label: "Final QR SVG")

    updated_params = Map.put(form_params, "qr_data", qr_data)
    qr_code = socket.assigns.qr_code || %QrCode{}

    changeset =
      qr_code
      |> QrCodes.change_qr_code(updated_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:qr_svg, qr_svg)
     |> assign(:generated_qr_code, qr_data)}
  end

  def handle_event("show_form", _params, socket) do
    {:noreply, assign(socket, :show_form, true)}
  end

  def handle_event("hide_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:form, to_form(QrCodes.change_qr_code(%QrCode{})))
     |> assign(:qr_svg, nil)
     |> assign(:generated_qr_code, nil)}
  end

  defp save_qr_code(socket, :edit, qr_code_params) do
    case QrCodes.update_qr_code(socket.assigns.qr_code, qr_code_params) do
      {:ok, qr_code} ->
        {:noreply,
         socket
         |> put_flash(:info, "QR code updated successfully")
         |> assign(:qr_codes, list_qr_codes())
         |> assign(:show_form, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_qr_code(socket, :new, qr_code_params) do
    qr_code_params = Map.put(qr_code_params, "created_by_id", socket.assigns.current_user.id)

    case QrCodes.create_qr_code(qr_code_params) do
      {:ok, qr_code} ->
        {:noreply,
         socket
         |> put_flash(:info, "QR code created successfully")
         |> assign(:qr_codes, list_qr_codes())
         |> assign(:show_form, false)
         |> assign(:form, to_form(QrCodes.change_qr_code(%QrCode{})))
         |> assign(:qr_svg, nil)
         |> assign(:generated_qr_code, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp list_qr_codes do
    QrCodes.list_qr_codes()
  end
end
