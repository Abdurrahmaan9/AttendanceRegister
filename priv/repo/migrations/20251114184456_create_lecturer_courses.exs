defmodule Register.Repo.Migrations.CreateLecturerCourses do
  use Ecto.Migration

  def change do
    create table(:lecturer_courses) do
      add :is_primary, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :course_id, references(:courses, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:lecturer_courses, [:user_id])
    create index(:lecturer_courses, [:course_id])
    create unique_index(:lecturer_courses, [:user_id, :course_id], name: :user_id_course_id_unique_index)
  end
end
