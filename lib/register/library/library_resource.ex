defmodule Register.Library.LibraryResource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "library_resources" do
    field :type, :string
    field :name, :string
    field :description, :string
    field :file_url, :string
    field :external_url, :string
    field :cover_image_url, :string
    field :settings, :map, default: %{}
    field :advanced_settings, :map, default: %{}

    belongs_to :board, Register.Library.LibraryBoard
    belongs_to :created_by, Register.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @types ~w(document link album video embedded assessment scorm lti h5p)

  def changeset(library_resource, attrs) do
    library_resource
    |> cast(attrs, [:type, :name, :description, :file_url, :external_url, :cover_image_url, :settings, :advanced_settings, :board_id, :created_by_id])
    |> validate_required([:type, :name])
    |> validate_inclusion(:type, @types)
  end
end
