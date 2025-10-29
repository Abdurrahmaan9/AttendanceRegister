defmodule Register.Repo.Migrations.UpdateStudentProgramSemesterType do
  use Ecto.Migration

  def up do
    drop_if_exists index(:student_programs, [:student_id, :program_id, :semester, :academic_year], name: :unique_student_program_semester)

    alter table(:student_programs) do
      add :semester_int, :integer, null: false, default: 1
    end

    execute("""
    UPDATE student_programs
    SET semester_int =
      CASE
        WHEN semester ~ '^[0-9]+$' THEN semester::integer
        WHEN lower(semester) IN ('fall', 'fall semester') THEN 1
        WHEN lower(semester) IN ('spring', 'spring semester') THEN 2
        ELSE 1
      END
    """)

    alter table(:student_programs) do
      remove :semester
    end

    rename table(:student_programs), :semester_int, to: :semester

    create unique_index(:student_programs, [:student_id, :program_id, :semester, :academic_year], name: :unique_student_program_semester)
  end

  def down do
    drop_if_exists index(:student_programs, [:student_id, :program_id, :semester, :academic_year], name: :unique_student_program_semester)

    alter table(:student_programs) do
      add :semester_text, :string, null: false, default: "Fall"
    end

    execute("""
    UPDATE student_programs
    SET semester_text =
      CASE semester
        WHEN 1 THEN 'Fall'
        WHEN 2 THEN 'Spring'
        ELSE semester::text
      END
    """)

    alter table(:student_programs) do
      remove :semester
    end

    rename table(:student_programs), :semester_text, to: :semester

    create unique_index(:student_programs, [:student_id, :program_id, :semester, :academic_year], name: :unique_student_program_semester)
  end
end
