defmodule Register.Permissions do
  @moduledoc """
  The Permissions context handles all permission-related operations.
  """

  import Ecto.Query, warn: false
  alias Register.Repo
  alias Register.Permissions.{Permission, RolePermission}

  @doc """
  Returns the list of all permissions.
  """
  def list_permissions do
    Repo.all(Permission)
  end

  @doc """
  Gets a single permission by ID.
  """
  def get_permission!(id), do: Repo.get!(Permission, id)


  def group_by_category(permissions) do
    Enum.group_by(permissions, fn permission -> permission.category end)
  end

  
  def has_permission?(role, permission_name) when is_binary(role) and is_binary(permission_name) do
    query =
      from p in Permission,
        join: rp in RolePermission,
        on: p.id == rp.permission_id,
        where: rp.role == ^role and p.name == ^permission_name,
        select: count() > 0

    Repo.one(query) || false
  end

  def has_permission?(role, permission) when is_atom(role) and is_atom(permission) do
    has_permission?(Atom.to_string(role), Atom.to_string(permission))
  end

  @doc """
  Returns all permissions for a given role.
  """
  def get_permissions(role) when is_binary(role) do
    query =
      from p in Permission,
        join: rp in RolePermission,
        on: p.id == rp.permission_id,
        where: rp.role == ^role,
        select: p.name

    query
    |> Repo.all()
    |> Enum.map(&String.to_atom/1)
    |> MapSet.new()
  end

  def get_permissions(role) when is_atom(role) do
    get_permissions(Atom.to_string(role))
  end

  @doc """
  Creates a new permission.
  """
  def create_permission(attrs \\ %{}) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a permission.
  """
  def update_permission(%Permission{} = permission, attrs) do
    permission
    |> Permission.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a permission.
  """
  def delete_permission(%Permission{} = permission) do
    Repo.delete(permission)
  end

  @doc """
  Returns permissions grouped by category.
  """
  def list_permissions_grouped do
    Permission
    |> Repo.all()
    |> Permission.group_by_category()
  end

  @doc """
  Gets all permissions for a specific role.
  """
  def get_permissions_for_role(role) when is_binary(role) do
    Permission
    |> Permission.for_role(role)
    |> Repo.all()
  end

  @doc """
  Checks if a role has a specific permission.
  """
  def has_permission?(role, permission_name) when is_binary(role) and is_binary(permission_name) do
    query =
      from p in Permission,
        join: rp in "role_permissions",
        on: p.id == rp.permission_id,
        where: rp.role == ^role and p.name == ^permission_name,
        select: count() > 0

    Repo.one(query) || false
  end

  @doc """
  Updates permissions for a role.
  """
  def update_role_permissions(role, permission_ids) when is_binary(role) and is_list(permission_ids) do
    Repo.transaction(fn ->
      # Delete existing permissions for this role
      from(rp in RolePermission, where: rp.role == ^role)
      |> Repo.delete_all()

      # Insert new permissions
      timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      permission_entries =
        permission_ids
        |> Enum.map(fn id ->
          %{
            role: role,
            permission_id: id,
            inserted_at: timestamp
          }
        end)

      Repo.insert_all(RolePermission, permission_entries)

      # Return the updated list of permissions for this role
      get_permissions_for_role(role)
    end)
  end

  @doc """
  Initializes default permissions in the database if they don't exist.
  This should be called during application startup.
  """
  def initialize_default_permissions do
    default_permissions = [
      %{
        name: "view_dashboard",
        description: "View the admin dashboard",
        category: "Dashboard"
      },
      %{
        name: "manage_users",
        description: "Create, edit, and delete users",
        category: "User Management"
      },
      %{
        name: "manage_roles",
        description: "Manage user roles and permissions",
        category: "User Management"
      },
      %{
        name: "view_reports",
        description: "View system reports",
        category: "Reports"
      },
      %{
        name: "export_data",
        description: "Export system data",
        category: "Data Management"
      }
    ]

    Enum.each(default_permissions, fn perm_attrs ->
      case Repo.get_by(Permission, name: perm_attrs[:name]) do
        nil -> create_permission(perm_attrs)
        _ -> :ok
      end
    end)
  end
end
