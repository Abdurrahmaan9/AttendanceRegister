defmodule Register.Emails.Email do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ["pending", "sent", "failed"]
  @required_fields [:to, :subject, :body, :status]

  schema "emails" do
    field :to, :string
    field :subject, :string
    field :body, :string
    field :sent_at, :utc_datetime
    field :status, :string, default: "pending"

    timestamps()
  end

  @doc false
  def changeset(email, attrs) do
    email
    |> cast(attrs, @required_fields ++ [:sent_at])
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, @statuses)
    |> validate_format(:to, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
  end

  def new_attrs(to, subject, body) do
    %{
      to: to,
      subject: subject,
      body: body,
      status: "pending"
    }
  end
end
