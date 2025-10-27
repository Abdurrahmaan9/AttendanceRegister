defmodule Register.Academic.ProgramCourse do
  use Ecto.Schema
  import Ecto.Changeset
  alias Register.Academic.Program
  alias Register.Courses.Course

  @valid_years [1, 2, 3, 4]
  @valid_semesters [1, 2]

  schema "program_courses" do
    field :year, :integer
    field :semester, :integer
    field :is_core, :boolean, default: true
    field :is_active, :boolean, default: true
    
    belongs_to :program, Program
    belongs_to :course, Course

    timestamps()
  end

  @doc false
  def changeset(program_course, attrs) do
    program_course
    |> cast(attrs, [:program_id, :course_id, :year, :semester, :is_core, :is_active])
    |> validate_required([:program_id, :course_id, :year, :semester])
    |> validate_inclusion(:year, @valid_years, message: "must be between 1 and 4")
    |> validate_inclusion(:semester, @valid_semesters, message: "must be 1 or 2")
    |> unique_constraint(:course_id, name: :program_courses_program_id_course_id_index)
    |> foreign_key_constraint(:program_id)
    |> foreign_key_constraint(:course_id)
  end
end
