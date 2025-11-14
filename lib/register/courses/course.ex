defmodule Register.Courses.Course do
  use Ecto.Schema
  import Ecto.Changeset
  alias Register.Academic.ProgramCourse

  schema "courses" do
    field :title, :string
    field :description, :string
    field :code, :string
    field :credits, :integer, default: 3
    field :is_active, :boolean, default: true

    has_many :program_courses, ProgramCourse
    has_many :programs, through: [:program_courses, :program]
    has_many :lecturer_courses, Register.Academic.LecturerCourse
    has_many :lecturers, through: [:lecturer_courses, :user]

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
