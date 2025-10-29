defmodule Register.Academic do
  @moduledoc """
  The Academic context handles program, course, and student relationships.
  """
  import Ecto.Query, warn: false
  alias Register.Repo
  alias Register.Academic.Program
  alias Register.Academic.ProgramCourse
  alias Register.Academic.StudentProgram
  alias Register.Courses.Course
  alias Register.Accounts.User

  # Program functions
  def list_programs do
    Repo.all(Program)
  end

  def get_program!(id), do: Repo.get!(Program, id)

  def create_program(attrs \\ %{}) do
    %Program{}
    |> Program.changeset(attrs)
    |> Repo.insert()
  end

  def update_program(%Program{} = program, attrs) do
    program
    |> Program.changeset(attrs)
    |> Repo.update()
  end

  def delete_program(%Program{} = program) do
    Repo.delete(program)
  end

  def change_program(%Program{} = program, attrs \\ %{}) do
    Program.changeset(program, attrs)
  end

  # Program Course functions
  def list_program_courses(program_id) do
    from(pc in ProgramCourse,
      where: pc.program_id == ^program_id,
      preload: [:course],
      order_by: [asc: :year, asc: :semester, asc: :id]
    )
    |> Repo.all()
  end

  def get_program_course!(id), do: Repo.get!(ProgramCourse, id)

  def create_program_course(attrs \\ %{}) do
    %ProgramCourse{}
    |> ProgramCourse.changeset(attrs)
    |> Repo.insert()
  end

  def update_program_course(%ProgramCourse{} = program_course, attrs) do
    program_course
    |> ProgramCourse.changeset(attrs)
    |> Repo.update()
  end

  def delete_program_course(%ProgramCourse{} = program_course) do
    Repo.delete(program_course)
  end

  def change_program_course(%ProgramCourse{} = program_course, attrs \\ %{}) do
    ProgramCourse.changeset(program_course, attrs)
  end

  # Helper functions
  def list_courses_not_in_program(program_id) do
    # First, get all course IDs that are already in the program
    assigned_course_ids = 
      from(pc in ProgramCourse,
        where: pc.program_id == ^program_id,
        select: pc.course_id
      )
      |> Repo.all()

    # Then find all courses that are not in the assigned_course_ids list
    from(c in Course,
      where: c.id not in ^assigned_course_ids
    )
    |> Repo.all()
  end

  def get_courses_by_program_and_semester(program_id, year, semester) do
    from(pc in ProgramCourse,
      where: pc.program_id == ^program_id and pc.year == ^year and pc.semester == ^semester,
      preload: [:course],
      order_by: [asc: :is_core, asc: :id]
    )
    |> Repo.all()
  end

  # Student Program functions
  def list_student_programs(student_id) do
    from(sp in StudentProgram,
      where: sp.student_id == ^student_id,
      preload: [:program],
      order_by: [desc: :is_active, desc: :enrollment_date]
    )
    |> Repo.all()
  end

  def list_students_in_program(program_id) do
    from(sp in StudentProgram,
      join: u in User, on: u.id == sp.student_id,
      where: sp.program_id == ^program_id and sp.is_active == true,
      preload: [:student],
      order_by: [asc: u.email]
    )
    |> Repo.all()
  end

  def get_student_program!(id), do: Repo.get!(StudentProgram, id) |> Repo.preload([:student, :program])

  def create_student_program(attrs \\ %{}) do
    %StudentProgram{}
    |> StudentProgram.changeset(attrs)
    |> Repo.insert()
  end

  def update_student_program(%StudentProgram{} = student_program, attrs) do
    student_program
    |> StudentProgram.changeset(attrs)
    |> Repo.update()
  end

  def delete_student_program(%StudentProgram{} = student_program) do
    Repo.delete(student_program)
  end

  def change_student_program(%StudentProgram{} = student_program, attrs \\ %{}) do
    StudentProgram.changeset(student_program, attrs)
  end

  # Returns all active courses assigned to a student through their active program enrollments
  def list_student_courses(student_id) do
    from(sp in StudentProgram,
      join: pc in ProgramCourse,
      on:
        pc.program_id == sp.program_id and
          pc.semester == type(sp.semester, :integer),
      join: p in Program, on: p.id == sp.program_id,
      join: c in Course, on: c.id == pc.course_id,
      where:
        sp.student_id == ^student_id and
          sp.is_active == true and
          pc.is_active == true and
          c.is_active == true,
      order_by: [asc: pc.year, asc: pc.semester, asc: c.code],
      select: %{
        course: c,
        year: pc.year,
        semester: pc.semester,
        program: p,
        academic_year: sp.academic_year
      }
    )
    |> Repo.all()
  end
end
