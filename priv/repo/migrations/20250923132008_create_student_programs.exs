defmodule Register.Repo.Migrations.CreateStudentPrograms do
  use Ecto.Migration

  def change do
    create table(:student_programs) do
      add :student_id, references(:users, on_delete: :delete_all), null: false
      add :program_id, references(:programs, on_delete: :delete_all), null: false
      add :enrollment_date, :date, null: false
      add :graduation_date, :date
      add :is_active, :boolean, default: true, null: false
      add :notes, :text
      add :semester, :string, null: false, default: "Fall"
      add :academic_year, :string, null: false, default: "2024-2025"

      timestamps()
    end

    create index(:student_programs, [:student_id])
    create index(:student_programs, [:program_id])
    create unique_index(:student_programs, [:student_id, :program_id], name: :student_program_unique_index)
    create index(:student_programs, [:student_id, :program_id, :semester, :academic_year],
          unique: true,
          name: :unique_student_program_semester
    )
  end
end
