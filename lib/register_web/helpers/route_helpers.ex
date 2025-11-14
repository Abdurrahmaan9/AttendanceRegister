defmodule RegisterWeb.RouteHelpers do
  @moduledoc """
  Helper functions for generating routes in the application.
  """
  
  alias RegisterWeb.Router.Helpers, as: Routes
  
  @doc """
  Generates the path for editing a lecturer's programs.
  
  ## Examples
  
      iex> lecturer_programs_path(%{id: 123})
      "/Admin/lecturers/123/programs"
  """
  def lecturer_programs_path(conn_or_socket, lecturer) do
    Routes.live_path(conn_or_socket, RegisterWeb.Admin.LecturerProgramsLive.Index, :edit, lecturer.id)
  end
  
  @doc """
  Generates the path for the lecturer programs index page.
  
  ## Examples
  
      iex> lecturer_programs_path(%{})
      "/Admin/lecturers"
  """
  def lecturer_programs_path(conn_or_socket) do
    Routes.live_path(conn_or_socket, RegisterWeb.Admin.LecturersLive.Index)
  end
end
