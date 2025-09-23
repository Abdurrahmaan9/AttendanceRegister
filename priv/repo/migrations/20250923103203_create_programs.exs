defmodule Register.Repo.Migrations.CreatePrograms do
  use Ecto.Migration

  def change do
    create table(:programs) do
      add :name, :string, null: false
      add :code, :string, null: false
      add :description, :text
      add :duration_years, :integer, null: false, default: 4
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:programs, [:code])

    create table(:program_courses) do
      add :program_id, references(:programs, on_delete: :delete_all), null: false
      add :course_id, references(:courses, on_delete: :delete_all), null: false
      add :year, :integer, null: false
      add :semester, :integer, null: false
      add :is_core, :boolean, default: true, null: false
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    create index(:program_courses, [:program_id])
    create index(:program_courses, [:course_id])
    create unique_index(:program_courses, [:program_id, :course_id])
    create index(:program_courses, [:program_id, :year, :semester])
  end
end
