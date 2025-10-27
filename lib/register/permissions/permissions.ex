defmodule Register.Permissions.Permissions do
  @moduledoc """
  Handles all permission-related functionality including checking permissions
  and managing access control.
  """

  @permission_sets %{
    # Admin has all permissions
    admin: MapSet.new([
      :view_dashboard, :manage_students, :manage_users, :view_students,
      :create_courses, :edit_courses, :delete_courses, :view_courses, :enroll_students,
      :record_attendance, :view_attendance, :edit_attendance, :attendance_reports,
      :view_reports, :create_reports, :view_analytics, :export_data,
      :manage_permissions, :qr_code_management, :otp_management, :view_audit_logs, :system_settings
    ]),

    # Lecturer has limited permissions
    lecturer: MapSet.new([
      :view_dashboard, :view_students,
      :create_courses, :edit_courses, :view_courses, :enroll_students,
      :record_attendance, :view_attendance, :edit_attendance, :attendance_reports,
      :view_reports, :view_analytics
    ]),

    # Student has basic view permissions
    student: MapSet.new([
      :view_courses, :view_attendance
    ])
  }

  @doc """
  Checks if a user with the given role has the specified permission.

  ## Examples
      iex> has_permission?(:admin, :manage_users)
      true

      iex> has_permission?(:student, :manage_users)
      false
  """
  @spec has_permission?(String.t() | atom(), String.t() | atom()) :: boolean()
  def has_permission?(role, permission) when is_binary(role) and is_binary(permission) do
    has_permission?(String.to_atom(role), String.to_atom(permission))
  end

  def has_permission?(role, permission) when is_atom(role) and is_atom(permission) do
    permissions = Map.get(@permission_sets, role, MapSet.new())
    MapSet.member?(permissions, permission)
  end

  @doc """
  Returns all permissions for a given role.
  """
  @spec get_permissions(atom()) :: MapSet.t()
  def get_permissions(role) when is_atom(role) do
    Map.get(@permission_sets, role, MapSet.new())
  end

  @doc """
  Returns a list of all available permissions with their descriptions.
  """
  def all_permissions do
    [
      # Core Management
      view_dashboard: "Access to admin dashboard and overview",
      manage_students: "Create, edit, delete and view student records",
      manage_users: "Create, edit, delete and view all user accounts",
      view_students: "Read-only access to student information",

      # Course Management
      create_courses: "Ability to create new courses",
      edit_courses: "Ability to modify course content and settings",
      delete_courses: "Ability to delete courses",
      view_courses: "Ability to view course listings and details",
      enroll_students: "Ability to enroll/unenroll students in courses",

      # Attendance Management
      record_attendance: "Ability to mark student attendance",
      view_attendance: "Ability to view attendance records and reports",
      edit_attendance: "Ability to modify existing attendance records",
      attendance_reports: "Generate and access attendance reports",

      # Reports & Analytics
      view_reports: "Access to system reports and data",
      create_reports: "Generate custom reports",
      view_analytics: "Access to analytics and dashboard metrics",
      export_data: "Export reports and data to external formats",

      # System Administration
      manage_permissions: "Modify user roles and permissions",
      qr_code_management: "Generate and manage QR codes for attendance",
      otp_management: "Manage one-time passwords and authentication",
      view_audit_logs: "View system audit logs and user activity",
      system_settings: "Configure system-wide settings"
    ]
  end
end
