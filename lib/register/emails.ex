defmodule Register.Emails do
  @moduledoc """
  The Emails context.
  """

  import Ecto.Query, warn: false
  alias Register.Repo
  alias Register.Emails.Email

  @doc """
  Creates an email record.
  """
  def create_email(attrs \\ %{}) do
    %Email{}
    |> Email.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Sends a welcome email to a new user with their credentials.
  """
  def send_welcome_email(email, name, password) do
    subject = "Welcome to Register App!"

    body = """
    Hello #{name},

    Your account has been created successfully.

    Here are your login details:
    Email: #{email}
    Password: #{password}

    Please change your password after your first login.

    Best regards,
    The Register Team
    """

    # Create email record
    case create_email(Email.new_attrs(email, subject, body)) do
      {:ok, email_record} ->
        # In a real app, you would use Bamboo or Swoosh to send the email
        # For now, we'll just log it and update the status
        IO.puts("Sending email to #{email} with subject: #{subject}")
        IO.puts("Email body:\n#{body}")

        # Update email status to sent
        email_record
        |> Ecto.Changeset.change(%{status: "sent", sent_at: DateTime.utc_now()})
        |> Repo.update()

      error ->
        error
    end
  end
end
