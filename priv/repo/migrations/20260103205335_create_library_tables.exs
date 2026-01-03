defmodule Register.Repo.Migrations.CreateLibraryTables do
  use Ecto.Migration

  def change do
    create table(:library_boards) do
      add :title, :string, null: false
      add :subtitle, :string
      add :description, :text
      add :cover_image_url, :string
      add :created_by_id, references(:users, on_delete: :nilify_all)
      add :is_public, :boolean, default: true, null: false
      add :views_count, :integer, default: 0
      add :likes_count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create table(:library_resources) do
      add :board_id, references(:library_boards, on_delete: :delete_all)
      add :type, :string, null: false # document, link, album, video, embedded, assessment, scorm, lti, h5p
      add :name, :string, null: false
      add :description, :text
      add :file_url, :string
      add :external_url, :string
      add :cover_image_url, :string
      add :settings, :map, default: %{}
      add :advanced_settings, :map, default: %{}
      add :created_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:library_boards, [:created_by_id])
    create index(:library_resources, [:board_id])
    create index(:library_resources, [:created_by_id])
  end
end
