defmodule Register.Repo.Migrations.CreateLecturerPrograms do
  use Ecto.Migration

  def change do
    create table(:lecturer_programs) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :program_id, references(:programs, on_delete: :delete_all), null: false
      add :is_primary, :boolean, default: false

      timestamps()
    end

    create unique_index(:lecturer_programs, [:user_id, :program_id])
    create index(:lecturer_programs, [:user_id])
    create index(:lecturer_programs, [:program_id])
  end
end
