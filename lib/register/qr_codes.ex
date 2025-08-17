defmodule Register.QrCodes do
  @moduledoc """
  The QrCodes context.
  """

  import Ecto.Query, warn: false
  alias Register.Repo

  alias Register.QrCodes.QrCode

  @doc """
  Returns the list of qr_codes.

  ## Examples

      iex> list_qr_codes()
      [%QrCode{}, ...]

  """
  def list_qr_codes do
    # First deactivate any expired QR codes
    deactivate_expired_qr_codes()
    
    # Then return all QR codes
    Repo.all(QrCode)
  end

  @doc """
  Returns the list of active qr_codes.
  """
  def list_active_qr_codes do
    from(q in QrCode, where: q.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets a single qr_code.

  Raises `Ecto.NoResultsError` if the Qr code does not exist.

  ## Examples

      iex> get_qr_code!(123)
      %QrCode{}

      iex> get_qr_code!(456)
      ** (Ecto.NoResultsError)

  """
  def get_qr_code!(id), do: Repo.get!(QrCode, id)

  @doc """
  Creates a qr_code.

  ## Examples

      iex> create_qr_code(%{field: value})
      {:ok, %QrCode{}}

      iex> create_qr_code(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_qr_code(attrs \\ %{}) do
    %QrCode{}
    |> QrCode.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a qr_code.

  ## Examples

      iex> update_qr_code(qr_code, %{field: new_value})
      {:ok, %QrCode{}}

      iex> update_qr_code(qr_code, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_qr_code(%QrCode{} = qr_code, attrs) do
    qr_code
    |> QrCode.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a qr_code.

  ## Examples

      iex> delete_qr_code(qr_code)
      {:ok, %QrCode{}}

      iex> delete_qr_code(qr_code)
      {:error, %Ecto.Changeset{}}

  """
  def delete_qr_code(%QrCode{} = qr_code) do
    Repo.delete(qr_code)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking qr_code changes.

  ## Examples

      iex> change_qr_code(qr_code)
      %Ecto.Changeset{data: %QrCode{}}

  """
  def change_qr_code(%QrCode{} = qr_code, attrs \\ %{}) do
    QrCode.changeset(qr_code, attrs)
  end

  @doc """
  Generates QR code data for a given class and program.
  """
  def generate_qr_data(class_name, program_name) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    "#{class_name}|#{program_name}|#{timestamp}"
  end

  @doc """
  Deactivates expired QR codes.
  """
  def deactivate_expired_qr_codes do
    now = NaiveDateTime.utc_now()
    
    from(q in QrCode, 
      where: q.is_active == true and not is_nil(q.expires_at) and q.expires_at < ^now
    )
    |> Repo.update_all(set: [is_active: false])
  end
end
