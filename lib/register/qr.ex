defmodule Register.QR do
  @moduledoc """
  Context module for handling QR code verification and processing.
  """

  import Ecto.Query, warn: false
  alias Register.Repo
  alias Register.QR.QRCode
  alias Register.Students.Student
  alias Register.Accounts.User

  @doc """
  Returns the list of qr_codes.
  """
  def list_qr_codes do
    QRCode
    |> order_by(desc: :inserted_at)
    |> preload(:created_by)
    |> Repo.all()
  end

  @doc """
  Gets a single qr_code.
  """
  def get_qr_code!(id) do
    QRCode
    |> preload(:created_by)
    |> Repo.get!(id)
  end

  @doc """
  Creates a qr_code.
  """
  def create_qr_code(attrs \\ %{}) do
    %QRCode{}
    |> QRCode.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a qr_code.
  """
  def update_qr_code(%QRCode{} = qr_code, attrs) do
    qr_code
    |> QRCode.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a qr_code.
  """
  def delete_qr_code(%QRCode{} = qr_code) do
    Repo.delete(qr_code)
  end

  @doc """
  Verifies if a QR code is valid and active.
  """
  def verify_qr_code(qr_data) do
    case Repo.get_by(QRCode, qr_data: qr_data, is_active: true) do
      nil -> 
        {:error, "QR code not found or inactive"}
      qr_code ->
        if qr_code.expires_at && DateTime.compare(qr_code.expires_at, DateTime.utc_now()) == :lt do
          {:error, "QR code has expired"}
        else
          {:ok, qr_code}
        end
    end
  end

  @doc """
  Verifies if a student is authorized to use a QR code.
  """
  def verify_student_authorization(%User{} = user, %QRCode{} = qr_code) do
    # Here you can add additional authorization logic
    # For example, check if the student is enrolled in the class
    # or if they have the correct permissions
    
    # For now, we'll just check if the user is active
    if user.is_active do
      {:ok, :authorized}
    else
      {:error, "User account is not active"}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking qr_code changes.
  """
  def change_qr_code(%QRCode{} = qr_code, attrs \\ %{}) do
    QRCode.changeset(qr_code, attrs)
  end

  @doc """
  Verifies a scanned QR code and returns the associated data.
  """
  def verify_qr_code(qr_data) do
    case decode_qr_data(qr_data) do
      {:ok, qr_code} ->
        # Check if the QR code is active and not expired
        cond do
          !qr_code.is_active ->
            {:error, "This QR code is no longer active"}
          
          qr_code.expires_at && DateTime.compare(qr_code.expires_at, DateTime.utc_now()) == :lt ->
            {:error, "This QR code has expired"}
          
          true ->
            {:ok, qr_code}
        end
      
      error ->
        error
    end
  end

  defp decode_qr_data(qr_data) do
    try do
      # This is a basic implementation. You might want to add more robust parsing
      # and validation based on your QR code format.
      case Jason.decode(qr_data) do
        {:ok, %{"id" => qr_code_id, "type" => _type}} ->
          case Repo.get(QRCode, qr_code_id) do
            nil -> {:error, "Invalid QR code"}
            qr_code -> {:ok, qr_code}
          end
          
        _ ->
          {:error, "Invalid QR code format"}
      end
    rescue
      _ -> {:error, "Failed to process QR code"}
    end
  end

  @doc """
  Verifies if a student is authorized to use the scanned QR code.
  """
  def verify_student_authorization(%Student{} = student, %QRCode{} = qr_code) do
    # Implement your authorization logic here
    # For example, check if the student is enrolled in the course
    # or has the necessary permissions
    
    # This is a placeholder implementation
    {:ok, %{student: student, qr_code: qr_code}}
  end

  @doc """
  Generates a QR code for a given record.
  """
  def generate_qr_code(%{id: id, __struct__: module}) do
    type = module |> Module.split() |> List.last() |> String.downcase()
    %{id: id, type: type, timestamp: System.system_time(:second)}
    |> Jason.encode!()
  end
end
