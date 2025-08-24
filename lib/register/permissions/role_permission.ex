defmodule Register.Permissions.RolePermission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "role_permissions" do
    field :role, :string
    belongs_to :permission, Register.Permissions.Permission, primary_key: true

    timestamps()
  end

  def changeset(role_permission, attrs) do
    role_permission
    |> cast(attrs, [:role, :permission_id])
    |> validate_required([:role, :permission_id])
    |> unique_constraint(:role, name: :role_permissions_role_permission_id_index)
  end
end
