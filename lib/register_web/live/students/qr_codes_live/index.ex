defmodule RegisterWeb.Students.QrCodesLive.Index do
  use RegisterWeb, :live_view
  alias Register.QR
  alias Register.QR.QRCode

  @impl true
  def mount(_params, session, socket) do
    current_user = get_session_user(session)

    socket = assign(socket,
      qr_codes: [],
      scanned_data: nil,
      error: nil,
      camera_active: false,
      current_user: current_user,
      changeset: QRCode.changeset(%QRCode{}, %{}),
      sidebar_open: false
    )

    if connected?(socket) do
      # Load any necessary data when the socket connects
      {:ok, load_initial_data(socket)}
    else
      {:ok, socket}
    end
  end

  defp get_session_user(session) do
    case session["user_token"] do
      nil -> nil
      token -> Register.Accounts.get_user_by_session_token(token)
    end
  end

  defp load_initial_data(socket) do
    current_user = socket.assigns.current_user

    if current_user do
      qr_codes = QR.list_qr_codes()
      assign(socket, qr_codes: qr_codes)
    else
      socket
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("start_scan", _params, %{assigns: %{current_user: nil}} = socket) do
    {:noreply,
      socket
      |> put_flash(:error, "You must be logged in to scan QR codes")
      |> assign(camera_active: false)
    }
  end

  def handle_event("start_scan", _params, socket) do
    # Toggle camera state
    new_state = !socket.assigns.camera_active

    {:noreply,
      socket
      |> assign(camera_active: new_state, scanned_data: nil, error: nil)
      |> clear_flash()
    }
  end

  @impl true
  def handle_event("process_qr", %{"data" => data}, %{assigns: %{current_user: nil}} = socket) do
    {:noreply,
      socket
      |> put_flash(:error, "You must be logged in to scan QR codes")
      |> assign(camera_active: false)
    }
  end

  def handle_event("process_qr", %{"data" => data}, socket) do
    case QR.verify_qr_code(data) do
      {:ok, qr_code} ->
        # Verify if the current user is authorized to use this QR code
        case QR.verify_student_authorization(socket.assigns.current_user, qr_code) do
          {:ok, _} ->
            # Handle successful verification
            handle_successful_scan(socket, qr_code)

          {:error, reason} ->
            {:noreply,
              socket
              |> put_flash(:error, "Authorization error: #{reason}")
              |> assign(error: reason, camera_active: false)
            }
        end

      {:error, reason} ->
        {:noreply,
          socket
          |> put_flash(:error, "Error: #{reason}")
          |> assign(error: reason, camera_active: true)
        }
    end
  end

  defp handle_successful_scan(socket, qr_code) do
    # Here you can add any additional processing for a successful scan
    # For example, log the scan, update attendance, etc.

    # Get the current time in the user's timezone
    now = DateTime.utc_now()

    # Format the QR code data for display
    qr_data = %{
      name: qr_code.name,
      class: qr_code.class_name,
      program: qr_code.program_name,
      scanned_at: now,
      expires_at: qr_code.expires_at
    }

    {:noreply,
      socket
      |> put_flash(:info, "QR Code scanned successfully!")
      |> assign(
        scanned_data: qr_data,
        camera_active: false,
        error: nil
      )
    }
  end

  @impl true
  def handle_event("scan_error", %{"error" => error}, socket) do
    error_message = case error do
      "NotAllowedError" -> "Camera access was denied. Please allow camera access to scan QR codes."
      "NotFoundError" -> "No camera found. Please connect a camera to scan QR codes."
      "NotSupportedError" -> "Camera not supported. Please try a different browser or device."
      "NotReadableError" -> "Camera is already in use by another application."
      "OverconstrainedError" -> "Camera constraints could not be satisfied. Please check your camera settings."
      _ -> "An error occurred while accessing the camera: #{error}"
    end

    {:noreply,
      socket
      |> put_flash(:error, error_message)
      |> assign(error: error_message, camera_active: false)
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Scan QR Code")
    |> assign(:camera_active, false)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    try do
      qr_code = QR.get_qr_code!(id)
      socket
      |> assign(:page_title, "QR Code Details")
      |> assign(:qr_code, qr_code)
      |> assign(:camera_active, false)
    rescue
      Ecto.NoResultsError ->
        socket
        |> put_flash(:error, "QR code not found")
        |> redirect(to: "/students/qr-codes")
    end
  end

  defp apply_action(socket, :verify, _params) do
    socket
    |> assign(:page_title, "Verify QR Code")
    |> assign(:camera_active, true)
  end

  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

end
