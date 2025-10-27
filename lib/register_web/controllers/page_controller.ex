defmodule RegisterWeb.PageController do
  use RegisterWeb, :controller

  def home(conn, _params) do
    case conn.assigns[:current_user] do
      %{role: "admin"} ->
        redirect(conn, to: "/Admin/dashboard")
      %{role: "lecturer"} ->
        redirect(conn, to: "/Lecturer/dashboard")
      %{role: "student"} ->
        redirect(conn, to: "/Students/dashboard")
      _ ->
        # For unauthenticated users, show the home page
        render(conn, :home, layout: false)
    end
  end

  def about(conn, _params) do
    # About page with navigation
    render(conn, :about, layout: false)
  end
end
