defmodule Register.Repo.Migrations.CreateCourses do
  use Ecto.Migration

  def change do
    create table(:courses) do
      add :title, :string, null: false
      add :description, :text
      add :code, :string, null: false
      add :credits, :integer, default: 3, null: false
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:courses, [:code])
  end
end
