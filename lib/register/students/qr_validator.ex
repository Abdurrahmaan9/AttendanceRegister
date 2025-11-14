defmodule Register.Students.QRValidator do
  @moduledoc """
  Validates and processes QR code data for students, attendance, and other purposes.
  """

  use RegisterWeb, :live_view
  require Logger

  alias Register.Students.Student
  alias RegisterWeb.Students.QRValidator

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

        # Add to scan history
        scan_entry = %{
          data: qr_data,
          type: result.type,
          timestamp: timestamp,
          success: true,
          message: result.message
        }

        socket =
          socket
          |> assign(:scanning, false)
          |> assign(:scan_result, result)
          |> assign(:error_message, nil)
          |> update(:scan_history, fn history ->
            [scan_entry | Enum.take(history, 9)]
          end)

        # You can add additional actions based on the type
        socket = handle_scan_result(result, socket)

        {:noreply, socket}

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
    IO.puts("Scanner error: #{error_message}")

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

  @impl true
  def handle_event("clear_history", _, socket) do
    {:noreply, assign(socket, :scan_history, [])}
  end

  # Handle different scan result types
  defp handle_scan_result(%{type: :student_id, student: student} = result, socket) do
    # Example: You could automatically navigate to student profile
    # or mark attendance, etc.
    IO.puts("Student scanned: #{student.first_name} #{student.last_name}")

    # You could push an event or send a notification
    # Phoenix.PubSub.broadcast(Register.PubSub, "students", {:student_scanned, student.id})

    socket
  end

  defp handle_scan_result(%{type: :attendance, attendance_code: code} = result, socket) do
    IO.puts("Attendance code scanned: #{code}")

    # Example: Mark attendance automatically
    # AttendanceService.mark_present(code, student_id)

    socket
  end

  defp handle_scan_result(%{type: :url} = result, socket) do
    IO.puts("URL scanned: #{result.url}")

    # You could redirect or open in new tab
    socket
  end

  defp handle_scan_result(_result, socket) do
    # Default handler for other types
    socket
  end

  @doc """
  Validates and processes the QR code data.

  ## Parameters
    * `qr_data` - String containing the QR code data (expected to be JSON)

  ## Returns
    * `{:ok, map()}` - If validation and processing is successful
    * `{:error, String.t()}` - If there's an error during validation or processing
  """
  @spec validate_and_process(String.t()) :: {:ok, map()} | {:error, String.t()}
  def validate_and_process(qr_data) when is_binary(qr_data) do
    with {:ok, decoded} <- Jason.decode(qr_data) do
      validate_qr_structure(decoded)
    else
      {:error, %Jason.DecodeError{}} ->
        Logger.error("Invalid QR code format: Not valid JSON")
        {:error, "Invalid QR code format"}
      error ->
        Logger.error("Error decoding QR code: #{inspect(error)}")
        {:error, "Error processing QR code"}
    end
  end

  defp validate_qr_structure(%{"type" => "attendance"} = qr_data) do
    required_fields = ["id", "t", "class_name", "program_name", "lecturer_id"]

    case validate_required_fields(qr_data, required_fields) do
      :ok ->
        # Convert timestamp to DateTime
        timestamp = DateTime.from_unix(qr_data["t"])

        # Check if timestamp is valid and not expired (within last 5 minutes)
        now = DateTime.utc_now()
        five_minutes_ago = DateTime.add(now, -300, :second)

        case timestamp do
          {:ok, timestamp} ->
            if DateTime.compare(timestamp, five_minutes_ago) == :lt do
              Logger.warning("QR code expired: #{inspect(timestamp)}")
              {:error, "QR code has expired. Please scan a new code."}
            else
              # Process the attendance QR code
              result = %{
                type: :attendance,
                id: qr_data["id"],
                class_name: qr_data["class_name"],
                program_name: qr_data["program_name"],
                lecturer_id: qr_data["lecturer_id"],
                timestamp: timestamp,
                message: "Attendance marked successfully for #{qr_data["class_name"]}"
              }
              {:ok, result}
            end

          {:error, _} ->
            Logger.error("Invalid timestamp in QR code: #{qr_data["t"]}")
            {:error, "Invalid timestamp in QR code"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_qr_structure(%{"type" => _unknown_type} = _qr_data) do
    {:error, "Unsupported QR code type"}
  end

  defp validate_qr_structure(_invalid_data) do
    {:error, "Invalid QR code format: Missing or invalid 'type' field"}
  end

  defp validate_required_fields(data, required_fields) do
    missing_fields = Enum.reject(required_fields, &Map.has_key?(data, &1))

    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, "Missing required fields: #{Enum.join(missing_fields, ", ")}"}
    end
  end
end
