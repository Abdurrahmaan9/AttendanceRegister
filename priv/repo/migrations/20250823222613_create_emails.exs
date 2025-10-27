defmodule Register.Repo.Migrations.CreateEmails do
  use Ecto.Migration

  def change do
    create table(:emails) do
      add :to, :string
      add :subject, :string
      add :body, :text
      add :sent_at, :utc_datetime
      add :status, :string

      timestamps(type: :utc_datetime)
    end
  end
end
