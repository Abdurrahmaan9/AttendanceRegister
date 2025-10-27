defmodule Register.Repo.Migrations.CreateQrCodes do
  use Ecto.Migration

  def change do
    create table(:qr_codes) do
      add :name, :string, null: false
      add :description, :text
      add :class_name, :string, null: false
      add :program_name, :string, null: false
      add :qr_data, :text, null: false
      add :is_active, :boolean, default: true
      add :expires_at, :naive_datetime
      add :created_by_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:qr_codes, [:created_by_id])
    create index(:qr_codes, [:class_name])
    create index(:qr_codes, [:program_name])
    create index(:qr_codes, [:is_active])
  end
end
