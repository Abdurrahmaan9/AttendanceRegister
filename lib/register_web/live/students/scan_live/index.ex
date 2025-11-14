defmodule RegisterWeb.Students.ScanLive.Index do
  use RegisterWeb, :live_view

  alias Register.Students.QRValidator

  @url "/Students/scan"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_path, @url)
      |> assign(:sidebar_open, false)
      |> assign(:scanning, false)
      |> assign(:scan_result, nil)
      |> assign(:error_message, nil)
      |> assign(:scan_history, [])

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("start_scan", _, socket) do
    socket =
      socket
      |> assign(:scanning, true)
      |> assign(:scan_result, nil)
      |> assign(:error_message, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("stop_scan", _, socket) do
    socket =
      socket
      |> assign(:scanning, false)
      |> assign(:scan_result, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("process_qr", %{"data" => qr_data} = params, socket) do
    # Log the scan attempt
    timestamp = params["timestamp"] || DateTime.utc_now() |> DateTime.to_iso8601()

    IO.puts("Processing QR code: #{qr_data}")
    IO.puts("Scan timestamp: #{timestamp}")

    # Validate and process the QR code
    case QRValidator.validate_and_process(qr_data) do
      {:ok, result} ->
        IO.puts("✅ QR Code validated successfully: #{inspect(result)}")

        # Record attendance
        case Register.Attendance.record_attendance(
          socket.assigns.current_user.id,
          result.lecturer_id,  # Using lecturer_id as course_id since that's what the QR code provides
          result.class_name,
          result.class_name,   # Using class_name as module_name
          Date.utc_today(),
          %{
            method: "qr",
            first_name: socket.assigns.current_user.first_name,
            last_name: socket.assigns.current_user.last_name
          }
        ) do
          {:ok, _attendance} ->
            # Add to scan history
            scan_entry = %{
              data: qr_data,
              type: result.type,
              timestamp: timestamp,
              success: true,
              message: "Attendance marked successfully for #{result.class_name}"
            }

            socket =
              socket
              |> assign(:scanning, false)
              |> assign(:scan_result, %{result | message: "Attendance marked successfully for #{result.class_name}"})
              |> assign(:error_message, nil)
              |> update(:scan_history, fn history ->
                [scan_entry | Enum.take(history, 9)]
              end)
              |> put_flash(:info, "Attendance successfully recorded for #{result.class_name}")

            {:noreply, socket}

          {:error, :already_marked} ->
            error_message = "You have already marked attendance for this session."
            IO.puts("❌ Attendance already marked: #{error_message}")

            # Add failed scan to history
            scan_entry = %{
              data: qr_data,
              type: :error,
              timestamp: timestamp,
              success: false,
              message: error_message
            }

            socket =
              socket
              |> assign(:scanning, false)
              |> assign(:scan_result, nil)
              |> assign(:error_message, error_message)
              |> update(:scan_history, fn history ->
                [scan_entry | Enum.take(history, 9)]
              end)
              |> put_flash(:info, "You have already marked attendance for this session #{result.class_name}")

            {:noreply, socket}

          {:error, changeset} ->
            error_message = "Failed to record attendance. Please try again."
            IO.error("Failed to record attendance: #{inspect(changeset)}")

            # Add failed scan to history
            scan_entry = %{
              data: qr_data,
              type: :error,
              timestamp: timestamp,
              success: false,
              message: error_message
            }

            socket =
              socket
              |> assign(:scanning, false)
              |> assign(:scan_result, nil)
              |> assign(:error_message, error_message)
              |> update(:scan_history, fn history ->
                [scan_entry | Enum.take(history, 9)]
              end)

            {:noreply, socket}
        end

      {:error, message} ->
        IO.puts("❌ QR Code validation failed: #{message}")

        # Add failed scan to history
        scan_entry = %{
          data: qr_data,
          type: :error,
          timestamp: timestamp,
          success: false,
          message: message
        }

        socket =
          socket
          |> assign(:scanning, false)
          |> assign(:scan_result, nil)
          |> assign(:error_message, message)
          |> update(:scan_history, fn history ->
            [scan_entry | Enum.take(history, 9)]
          end)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("scan_error", %{"error" => error_message}, socket) do
    socket =
      socket
      |> assign(:scanning, false)
      |> assign(:error_message, error_message)

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_result", _, socket) do
    socket =
      socket
      |> assign(:scan_result, nil)
      |> assign(:error_message, nil)

    {:noreply, socket}
  end

  # Private functions
  defp process_qr_data(qr_data) do
    # Basic validation - you can extend this based on your QR code format
    cond do
      String.length(qr_data) == 0 ->
        {:error, "Empty QR code data"}

      # Check if it's a valid student ID format (example: STU-12345)
      String.starts_with?(qr_data, "STU-") ->
        # Here you could validate against your database
        {:ok, %{type: :student_id, data: qr_data, message: "Student ID scanned successfully"}}

      # Check if it's an attendance code
      String.starts_with?(qr_data, "ATT-") ->
        {:ok, %{type: :attendance, data: qr_data, message: "Attendance code scanned successfully"}}

      # Default case
      true ->
        {:ok, %{type: :unknown, data: qr_data, message: "QR code scanned: #{qr_data}"}}
    end
  end
end
