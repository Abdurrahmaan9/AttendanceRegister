defmodule Register.Library.LibraryBoard do
  use Ecto.Schema
  import Ecto.Changeset

  schema "library_boards" do
    field :title, :string
    field :subtitle, :string
    field :description, :string
    field :cover_image_url, :string
    field :is_public, :boolean, default: true
    field :views_count, :integer, default: 0
    field :likes_count, :integer, default: 0

    belongs_to :created_by, Register.Accounts.User
    has_many :resources, Register.Library.LibraryResource, foreign_key: :board_id

    timestamps(type: :utc_datetime)
  end

  def changeset(library_board, attrs) do
    library_board
    |> cast(attrs, [:title, :subtitle, :description, :cover_image_url, :is_public, :views_count, :likes_count, :created_by_id])
    |> validate_required([:title])
  end
end
