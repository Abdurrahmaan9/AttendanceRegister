defmodule RegisterWeb.Plugs.MfaAuth do
  use RegisterWeb, :controller
  import Plug.Conn

  alias RegisterWeb.Accounts.User
  alias Register.Otps

  def generate_one_time_pass() do
    secret = NimbleTOTP.secret()

    one_time_pass = NimbleTOTP.verification_code(secret)

    {secret, one_time_pass}
  end

  def valid_one_time_pass?(one_time_pass, secret), do: NimbleTOTP.valid?(secret, one_time_pass)

  def valid_code?(otp, secret) do
    time = System.os_time(:second)

    NimbleTOTP.valid?(secret, otp, time: time) or NimbleTOTP.valid?(secret, otp, time: time - 30)
  end

  def invalidate_secret(conn) do
    updated_plug_session =
      conn.private[:plug_session]
      |> Map.drop(["user_secret"])

    conn
    |> put_private(:plug_session, updated_plug_session)
  end

  # Attendance OTP integration
  def generate_attendance_pass(lecturer, course, opts \\ []) do
    Otps.generate_attendance_otp(lecturer, course, opts)
  end

  def valid_attendance_code?(code) when is_binary(code) do
    case Otps.verify_attendance_otp(code) do
      {:ok, course_info} -> {:ok, course_info}
      other -> other
    end
  end
end
