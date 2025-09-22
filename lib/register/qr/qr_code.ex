defmodule Register.QR.QRCode do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "qr_codes" do
    field :name, :string
    field :description, :string
    field :class_name, :string
    field :program_name, :string
    field :qr_data, :string
    field :is_active, :boolean, default: true
    field :expires_at, :naive_datetime

    # Relationships
    belongs_to :created_by, Register.Accounts.User, type: :binary_id
    
    timestamps(type: :utc_datetime)
  end

  @doc """
  A changeset for creating or updating a QR code.
  """
  def changeset(qr_code, attrs) do
    qr_code
    |> cast(attrs, [:name, :description, :class_name, :program_name, :qr_data, :is_active, :expires_at, :created_by_id])
    |> validate_required([:name, :class_name, :program_name, :qr_data, :created_by_id])
    |> unique_constraint(:qr_data, name: :qr_codes_qr_data_index)
    |> foreign_key_constraint(:created_by_id)
  end

  @doc """
  A changeset specifically for creating a new QR code.
  Generates a unique code if one isn't provided.
  """
  def create_changeset(qr_code, attrs) do
    qr_code
    |> changeset(attrs)
    |> generate_code()
  end

  defp generate_code(changeset) do
    if get_field(changeset, :code) do
      changeset
    else
      code = 
        :crypto.strong_rand_bytes(16)
        |> Base.url_encode64(padding: false)
        
      put_change(changeset, :code, code)
    end
  end

  defp validate_data(changeset) do
    validate_change(changeset, :data, fn :data, data ->
      case Jason.encode(data) do
        {:ok, _} -> []
        {:error, _} -> [data: "is not valid JSON"]
      end
    end)
  end

  @doc """
  A query that returns only active QR codes.
  """
  def active(query) do
    from q in query,
      where: q.is_active == true,
      where: is_nil(q.expires_at) or q.expires_at > ^DateTime.utc_now()
  end

  @doc """
  A query that returns QR codes created by a specific user.
  """
  def by_user(query, user_id) do
    from q in query,
      where: q.created_by_id == ^user_id
  end
end
