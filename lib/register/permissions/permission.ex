defmodule Register.Permissions.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :name, :string
    field :description, :string
    field :category, :string

    timestamps()
  end

  def group_by_category(permissions) do
    Enum.group_by(permissions, fn permission -> permission.category end)
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :description, :category])
    |> validate_required([:name, :description, :category])
    |> unique_constraint(:name)
  end
end
