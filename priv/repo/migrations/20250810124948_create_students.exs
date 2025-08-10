defmodule Register.Repo.Migrations.CreateStudents do
  use Ecto.Migration

  def change do
    create table(:students) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :string, null: false
      add :program, :string, null: false

      timestamps()
    end

    create unique_index(:students, [:email])
  end
end
