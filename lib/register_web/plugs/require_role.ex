defmodule RegisterWeb.Plugs.RequireRole do
  import Plug.Conn
  import Phoenix.Controller

  def init(roles), do: roles

  def call(conn, roles) do
    user = conn.assigns.current_user

    if user && user.role in roles do
      conn
    else
      conn
      |> put_flash(:error, "Unauthorized access")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
