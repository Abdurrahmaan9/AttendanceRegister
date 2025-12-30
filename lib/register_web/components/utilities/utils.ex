defmodule RegisterWeb.Utils do
  @moduledoc """
  Utility functions for reusable UI components and helpers.
  """

  @doc """
  Returns the appropriate Tailwind CSS classes for status styling.

  ## Examples

      iex> Utils.status_color_class(true)
      "bg-green-100 text-green-800"

      iex> Utils.status_color_class(false)
      "bg-red-100 text-red-800"

      iex> Utils.status_color_class("active")
      "bg-green-100 text-green-800"
  """
  def status_color_class(status) do
    case status do
      true -> "bg-green-100 text-green-800"
      false -> "bg-red-100 text-red-800"
      "active" -> "bg-green-100 text-green-800"
      "inactive" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  @doc """
  Formats a status value for display.

  ## Examples

      iex> Utils.format_status(true)
      "Active"

      iex> Utils.format_status(false)
      "Inactive"

      iex> Utils.format_status("active")
      "Active"
  """
  def format_status(status) do
    case status do
      true -> "Active"
      false -> "Inactive"
      "active" -> "Active"
      "inactive" -> "Inactive"
      _ -> "Unknown"
    end
  end
end
