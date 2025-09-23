defmodule Register.Repo.Migrations.AddSemesterToStudentPrograms do
  use Ecto.Migration

  def change do
    alter table(:student_programs) do
      add :semester, :string, null: false, default: "Fall"
      add :academic_year, :string, null: false, default: "2024-2025"
    end

    create index(:student_programs, [:student_id, :program_id, :semester, :academic_year],
             unique: true,
             name: :unique_student_program_semester
    )
  end
end
