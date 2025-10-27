defmodule RegisterWeb.OtpController do
  use RegisterWeb, :controller
  import Plug.Conn

  alias Register.Accounts
  alias RegisterWeb.Plugs.MfaAuth
  alias Register.Emails.Email

  def new(conn, _) do
    # we want to see if our token is empty, and if it is we redirect them back to the new session page
    # the goal here is to make sure we have the same conn that went through the session controller
    with %{} <- fetch_secret_from_session(conn) do
      render(conn, "otp.html")
      # |> redirect(:RegisterWeb.Components.OtpManagement.OtpMangement)
    else
      _ ->
        conn
        |> put_flash(:error, "Page not found")
        |> put_status(404)
        |> redirect(to: ~p"/")
    end
  end

  def create(conn, %{"user" => %{"otp" => one_time_pass}}) do
    # To verify the one_time_pass that comes in through the form we need the secret token off the conn
    # we also need the user_id to know who we're building the session for
    %{"user_secret" => %{"secret" => secret, "user_id" => user_id}} = get_session(conn)
    user = Accounts.get_user!(user_id)

    case MfaAuth.valid_code?(one_time_pass, secret) do
      true ->
        conn
        |> delete_session("user_secret")
        |> put_flash(:info, "Login successful!")
        |> put_session(:current_user, user.id)
        |> put_session(:session_timeout_at, session_timeout_at())
        |> redirect(to: ~p"/dashboard")

      false ->
        conn
        |> put_flash(:error, "The authentication code you entered was invalid!")
        |> render("otp.html")
    end
  end

  def resend_email(conn, _) do
    %{"user_secret" => %{"secret" => secret, "user_id" => user_id}} = get_session(conn)
    user = Accounts.get_user!(user_id)

    {secret, one_time_pass} = MfaAuth.generate_one_time_pass()
    send_otp(user, one_time_pass)

    conn
    |> delete_session("user_secret")
    |> put_session("user_secret", %{"secret" => secret, "user_id" => user.id})
    |> put_flash(:info, "A new two-factor authentication code was sent to your email!")
    |> render("otp.html")

    # |> redirect("otp.html")
  end

  defp fetch_secret_from_session(conn) do
    get_session(conn, "user_secret") |> IO.inspect()
  end

  defp session_timeout_at do
    DateTime.utc_now() |> DateTime.to_unix() |> (&(&1 + 120)).()
    # 3_600
  end

  ################################## NOTIFICATIONS #############################
  defp send_otp(user, one_time_pass) do
    subject = "Register OTP"

    Sms.create(%{type: subject, mobile: user.phone, msg: one_time_pass})
    Email.send_mail(user.email, subject, one_time_pass)
  end
end
