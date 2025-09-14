defmodule Register.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :name, :string, null: false
      add :description, :text
      add :category, :string
      
      timestamps()
    end

    create unique_index(:permissions, [:name])
    create index(:permissions, [:category])

    create table(:role_permissions, primary_key: false) do
      add :role, :string, null: false
      add :permission_id, references(:permissions, on_delete: :delete_all), null: false
      
      timestamps()
    end

    create index(:role_permissions, [:role])
    create unique_index(:role_permissions, [:role, :permission_id], name: :role_permissions_role_permission_id_index)
  end
end
