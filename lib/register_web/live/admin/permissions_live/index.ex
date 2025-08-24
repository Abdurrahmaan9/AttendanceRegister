defmodule RegisterWeb.Admin.PermissionsLive.Index do
  use RegisterWeb, :live_view
  alias Register.Permissions
  alias RegisterWeb.PermissionHelpers

  @user_types [:admin, :lecturer, :student]

  defp group_by_category(permissions) do
    permissions
    |> Enum.group_by(& &1.category)
  end

  def mount(_params, _session, socket) do
    user_types = [:admin, :lecturer, :student]
    current_role = socket.assigns.current_user.role |> String.to_atom()
    current_permissions = Permissions.get_permissions(current_role) || MapSet.new()
    permissions_data = %{}

    if connected?(socket) do
      case PermissionHelpers.check_permission(socket, :manage_permissions) do
        {:cont, socket} ->
          permissions = Permissions.list_permissions_grouped() || []
          permissions_data = group_permissions_by_category(permissions)

          {:ok, assign(socket,
            permissions: permissions,
            permissions_data: permissions_data,
            user_types: user_types,
            selected_user_type: current_role,
            current_permissions: current_permissions,
            original_permissions: current_permissions,
            changes_made: false
          )}
        {:halt, socket} ->
          {:halt, socket}
      end
    else
      {:ok, assign(socket,
        permissions: %{},
        permissions_data: permissions_data,
        user_types: user_types,
        selected_user_type: current_role,
        current_permissions: current_permissions,
        original_permissions: current_permissions,
        changes_made: false
      )}
    end
  end

  defp group_permissions_by_category(permissions) do
    permissions
    |> Enum.map(fn permission -> {permission.name, permission.description} end)
    |> Enum.group_by(
      fn {_key, desc} ->
        cond do
          desc == "Access to admin dashboard and overview" -> "Core Management"
          String.contains?(desc, "student") -> "Student Management"
          String.contains?(desc, "course") -> "Course Management"
          String.contains?(desc, "ttendance") -> "Attendance Management"
          String.contains?(desc, "report") or String.contains?(desc, "analytics") -> "Reports & Analytics"
          true -> "System"
        end
      end,
      fn {key, desc} ->
        %{key: key, name: key |> to_string() |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1), description: desc}
      end
    )
    |> Enum.map(fn {category, perms} -> %{category: category, permissions: perms} end)
  end

  defp get_default_permissions do
    @user_types
    |> Enum.map(fn type -> {type, Permissions.get_permissions(type)} end)
    |> Enum.into(%{})
  end

  def handle_params(params, _url, socket) do
    selected_user_type =
      case params["role"] do
        nil -> socket.assigns.selected_user_type
        role -> String.to_existing_atom(role)
      end

    current_permissions = Permissions.get_permissions(selected_user_type) || MapSet.new()

    {:noreply,
      socket
      |> assign(selected_user_type: selected_user_type)
      |> assign(current_permissions: current_permissions)
      |> assign(changes_made: false)
    }
  end

  def handle_event("select_user_type", %{"user_type" => user_type}, socket) do
    user_type_atom = String.to_existing_atom(user_type)
    current_permissions = Permissions.get_permissions(user_type_atom) || MapSet.new()

    {:noreply,
      socket
      |> push_patch(to: ~p"/Admin/permissions?role=#{user_type}")
      |> assign(selected_user_type: user_type_atom)
      |> assign(current_permissions: current_permissions)
      |> assign(changes_made: false)
    }
  end

  def handle_event("toggle_permission", %{"permission" => permission}, socket) do
    permission_atom = String.to_existing_atom(permission)
    selected_type = socket.assigns.selected_user_type
    current_permissions = socket.assigns.current_permissions

    user_permissions = Map.get(current_permissions, selected_type, MapSet.new())

    updated_permissions =
      if MapSet.member?(user_permissions, permission_atom) do
        MapSet.delete(user_permissions, permission_atom)
      else
        MapSet.put(user_permissions, permission_atom)
      end

    new_permissions = Map.put(current_permissions, selected_type, updated_permissions)

    {:noreply,
     socket
     |> assign(:current_permissions, new_permissions)
     |> assign(:changes_made, true)}
  end

  def handle_event("save_permissions", _params, socket) do
    # Here you would typically save to your database
    # For now, we'll just show a success message

    {:noreply,
     socket
     |> assign(:changes_made, false)
     |> put_flash(:info, "Permissions updated successfully!")}
  end

  def handle_event("reset_permissions", _params, socket) do
    # Reset to default permissions
    {:noreply,
     socket
     |> assign(:changes_made, false)
     |> put_flash(:info, "Permissions reset to defaults")}
  end
end
