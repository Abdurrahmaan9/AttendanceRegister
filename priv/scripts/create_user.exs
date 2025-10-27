# Script to create a user for the Register application
# Usage: mix run priv/scripts/create_user.exs

alias Register.Accounts
alias Register.Accounts.User
alias Register.Repo

# Generate unique email with timestamp
timestamp = DateTime.utc_now() |> DateTime.to_unix()
user_attrs = %{
  email: "user#{timestamp}@example.com",
  password: "password123!"
}

# Create the user
case Accounts.register_user(user_attrs) do
  {:ok, user} ->
    IO.puts("✅ User created successfully!")
    IO.puts("Email: #{user.email}")
    IO.puts("ID: #{user.id}")
    IO.puts("Created at: #{user.inserted_at}")
    
    # Confirm the user (skip email confirmation)
    changeset = User.confirm_changeset(user)
    case Repo.update(changeset) do
      {:ok, confirmed_user} ->
        IO.puts("✅ User confirmed successfully!")
        IO.puts("Confirmed at: #{confirmed_user.confirmed_at}")
      {:error, changeset} ->
        IO.puts("❌ Failed to confirm user:")
        IO.inspect(changeset.errors)
    end

  {:error, changeset} ->
    IO.puts("❌ Failed to create user:")
    IO.inspect(changeset.errors)
end
