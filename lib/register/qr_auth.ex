defmodule Register.QrAuth do
  @moduledoc """
  Handles QR code verification for attendance marking.
  """

  alias Register.MfaAuth

  @doc """
  Verifies a QR code string and returns course information if valid.

  The QR code should be in the format: "module_code:otp"

  ## Examples
      iex> verify_qr_code("CS101:123456")
      {:ok, %{course_id: 1, module_code: "CS101", ...}}

      iex> verify_qr_code("invalid")
      {:error, :invalid_format}
  """
  @spec verify_qr_code(String.t()) :: {:ok, map()} | {:error, atom() | String.t()}
  def verify_qr_code(qr_data) do
    with [module_code, otp] when module_code != "" and otp != "" <- String.split(qr_data, ":", parts: 2),
         {:ok, course_info} <- MfaAuth.valid_attendance_code?(module_code, otp) do
      {:ok, course_info}
    else
      [_invalid_format] ->
        {:error, :invalid_format}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, :invalid_format}
    end
  end
end
