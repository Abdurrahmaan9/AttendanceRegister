defmodule Register.Otps.Otp do
  use Ecto.Schema
  import Ecto.Changeset

  schema "otps" do
    field :code, :string
    field :is_active, :boolean, default: true
    field :expires_at, :utc_datetime
    field :course_name, :string
    field :module_code, :string
    field :lecturer_name, :string
    field :location, :string
    field :session_date, :date

    belongs_to :created_by, Register.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(otp, attrs) do
    otp
    |> cast(attrs, [
      :code, :is_active, :expires_at,
      :course_name, :module_code, :lecturer_name, :location, :session_date
    ])
    |> validate_required([
      :code, :is_active,
      :course_name, :module_code, :session_date
    ])
    |> validate_length(:code, min: 6, max: 6)
    |> validate_length(:purpose, max: 100)
    |> foreign_key_constraint(:created_by_id)
  end

  def generate_code(length \\ 6) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
    |> String.upcase()
  end
end
