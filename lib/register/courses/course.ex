defmodule Register.Courses.Course do
  use Ecto.Schema
  import Ecto.Changeset

  schema "courses" do
    field :title, :string
    field :description, :string
    field :code, :string
    field :credits, :integer, default: 3
    field :is_active, :boolean, default: true

    timestamps()
  end

  @doc false
  def changeset(course, attrs) do
    course
    |> cast(attrs, [:title, :description, :code, :credits, :is_active])
    |> validate_required([:title, :code, :credits])
    |> unique_constraint(:code)
  end
end
