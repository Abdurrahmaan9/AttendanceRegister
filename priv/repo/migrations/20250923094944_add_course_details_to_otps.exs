defmodule Register.Repo.Migrations.AddCourseDetailsToOtps do
  use Ecto.Migration

  def change do
    alter table(:otps) do
      add :course_id, :integer, null: false
      add :course_name, :string, null: false
      add :module_code, :string, null: false
      add :lecturer_name, :string
      add :location, :string
      add :session_date, :date, null: false
    end

    create index(:otps, [:course_id])
    create index(:otps, [:module_code])
  end
end
