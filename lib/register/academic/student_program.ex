defmodule Register.Academic.StudentProgram do
  use Ecto.Schema
  import Ecto.Changeset

  schema "student_programs" do
    field :enrollment_date, :date
    field :graduation_date, :date
    field :is_active, :boolean, default: true
    field :notes, :string
    field :semester, :integer, default: 1
    field :academic_year, :string, default: "2024-2025"
    
    belongs_to :student, Register.Accounts.User
    belongs_to :program, Register.Academic.Program

    timestamps()
  end

  @doc false
  def changeset(student_program, attrs) do
    student_program
    |> cast(attrs, [:student_id, :program_id, :enrollment_date, :graduation_date, :is_active, :notes, :semester, :academic_year])
    |> validate_required([:student_id, :program_id, :enrollment_date, :is_active, :semester, :academic_year])
    |> validate_inclusion(:semester, [1, 2], message: "must be 1 or 2")
    |> unique_constraint([:student_id, :program_id, :semester, :academic_year], name: :unique_student_program_semester)
  end
end
