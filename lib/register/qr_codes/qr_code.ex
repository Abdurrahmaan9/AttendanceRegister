defmodule Register.QrCodes.QrCode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "qr_codes" do
    field :name, :string
    field :description, :string
    field :class_name, :string
    field :program_name, :string
    field :qr_data, :string
    field :is_active, :boolean, default: true
    field :expires_at, :naive_datetime

    belongs_to :created_by, Register.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(qr_code, attrs) do
    qr_code
    |> cast(attrs, [:name, :description, :class_name, :program_name, :qr_data, :is_active, :expires_at, :created_by_id])
    |> validate_required([:name, :class_name, :program_name, :qr_data, :created_by_id])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:class_name, min: 1, max: 255)
    |> validate_length(:program_name, min: 1, max: 255)
    |> validate_length(:description, max: 1000)
    |> foreign_key_constraint(:created_by_id)
  end
end
