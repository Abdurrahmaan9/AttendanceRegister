defmodule Register.Academic.Program do
  use Ecto.Schema
  import Ecto.Changeset

  schema "programs" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :duration_years, :integer, default: 4
    field :is_active, :boolean, default: true

    has_many :program_courses, Register.Academic.ProgramCourse
    has_many :courses, through: [:program_courses, :course]
    has_many :lecturer_programs, Register.Academic.LecturerProgram
    has_many :lecturers, through: [:lecturer_programs, :user]

    timestamps()
  end

  @doc false
  def changeset(program, attrs) do
    program
    |> cast(attrs, [:name, :code, :description, :duration_years, :is_active])
    |> validate_required([:name, :code])
    |> unique_constraint(:code)
  end
end
