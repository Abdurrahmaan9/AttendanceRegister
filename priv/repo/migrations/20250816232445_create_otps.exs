defmodule Register.Repo.Migrations.CreateOtps do
  use Ecto.Migration

  def change do
    create table(:otps) do
      add :code, :string, null: false
      add :is_active, :boolean, default: true, null: false
      add :expires_at, :utc_datetime, null: false
      add :purpose, :string, null: false
      add :metadata, :map, default: "{}", null: false
      add :created_by_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:otps, [:created_by_id])
  end
end
