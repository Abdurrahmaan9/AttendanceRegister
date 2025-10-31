defmodule Register.Repo.Migrations.CreateAttendanceRecords do
  use Ecto.Migration

  def change do
    create table(:attendance_records) do
      add :first_name, :string
      add :last_name, :string
      add :module_code, :string, null: false
      add :module_name, :string, null: false
      add :session_date, :date, null: false
      add :method, :string, null: false, default: "otp"
      add :student_id, references(:users, on_delete: :nothing), null: false
      add :course_id, references(:courses, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:attendance_records, [:student_id])
    create index(:attendance_records, [:course_id])
    create index(:attendance_records, [:session_date])
    create index(:attendance_records, [:module_code])
  end
end
