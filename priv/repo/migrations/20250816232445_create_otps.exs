defmodule Register.Repo.Migrations.CreateOtps do
  use Ecto.Migration

  def change do
    create table(:otp) do
      add :code, :string, null: false
      add :is_active, :boolean, default: true, null: false
      add :expires_at, :utc_datetime, null: false
      add :purpose, :string, null: false
      add :course_id, :integer, null: false
      add :course_name, :string, null: false
      add :module_code, :string, null: false
      add :lecturer_name, :string
      add :location, :string
      add :session_date, :date, null: false
      add :created_by_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:otp, [:code])
    create index(:otp, [:created_by_id])
  end
end
