defmodule RegisterWeb.RouteHelpers do
  @moduledoc """
  Helper functions for generating routes in the application.
  """

  alias RegisterWeb.Router.Helpers, as: Routes

  @doc """
  Generates the path for editing a lecturer's courses.

  ## Examples

      iex> lecturer_courses_path(%{id: 123})
      "/Admin/lecturers/123/courses"
  """
  def lecturer_courses_path(conn_or_socket, lecturer) do
    Routes.live_path(conn_or_socket, RegisterWeb.Admin.LecturerCoursesLive.Index, :edit, lecturer.id)
  end

  @doc """
  Generates the path for the lecturer courses index page.

  ## Examples

      iex> lecturer_courses_path(%{})
      "/Admin/lecturers"
  """
  def lecturer_courses_path(conn_or_socket) do
    Routes.live_path(conn_or_socket, RegisterWeb.Admin.LecturerCoursesLive.Index)
  end
end
