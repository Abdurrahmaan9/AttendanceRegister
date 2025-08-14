defmodule RegisterWeb.Helpers.RoleHelper do
  @moduledoc """
  Helper functions for role-based UI components.
  """

  def role_class("admin"), do: "bg-purple-100 text-purple-800"
  def role_class("lecturer"), do: "bg-blue-100 text-blue-800"
  def role_class("student"), do: "bg-green-100 text-green-800"
  def role_class(_), do: "bg-gray-100 text-gray-800"
end
