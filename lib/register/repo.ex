defmodule Register.Repo do
  use Ecto.Repo,
    otp_app: :register,
    adapter: Ecto.Adapters.Postgres
end
