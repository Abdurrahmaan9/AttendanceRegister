defmodule Register.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Register.Permissions.Permission
  alias Register.Repo

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Register.Repo,

      # Start the Telemetry supervisor
      RegisterWeb.Telemetry,

      # Start the PubSub system
      {Phoenix.PubSub, name: Register.PubSub},

      # Start the Endpoint (http/https)
      RegisterWeb.Endpoint,

      # Start the Finch HTTP client for sending emails
      {Finch, name: Register.Finch},

      # Start attendance summary cache refresher (runs every 2 hours)
      Register.Attendance.SummaryCache,

      # Start attendance data updater (runs every 5 minutes)
      Register.AttendanceUpdater,

      # Start the permission initialization worker
      {Task, &initialize_default_permissions/0}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Register.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RegisterWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Initialize default permissions in the database
  def initialize_default_permissions do
    default_permissions = [
      %{
        name: "view_dashboard",
        description: "Access to admin dashboard and overview",
        category: "Core Management"
      },
      %{
        name: "manage_users",
        description: "Manage user accounts and permissions",
        category: "User Management"
      },
      %{
        name: "manage_roles",
        description: "Manage roles and their permissions",
        category: "Role Management"
      },
      %{
        name: "manage_permissions",
        description: "Manage system permissions",
        category: "Permission Management"
      }
      # Add other default permissions here
    ]

    permissions = Enum.map(default_permissions, fn perm_attrs ->
      case Repo.get_by(Permission, name: perm_attrs.name) do
        nil ->
          {:ok, permission} =
            %Permission{}
            |> Permission.changeset(perm_attrs)
            |> Repo.insert()
          permission
        permission ->
          permission
      end
    end)

    # Then ensure admin has all permissions
    admin_permission_ids = Enum.map(permissions, & &1.id)
    Register.Permissions.update_role_permissions("admin", admin_permission_ids)
  end
end
