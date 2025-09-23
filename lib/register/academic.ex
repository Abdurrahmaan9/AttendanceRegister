defmodule Register.Academic do
  @moduledoc """
  The Academic context handles program and course relationships.
  """
  import Ecto.Query, warn: false
  alias Register.Repo
  alias Register.Academic.Program
  alias Register.Academic.ProgramCourse
  alias Register.Courses.Course

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
    assigned_course_ids = 
      from(pc in ProgramCourse,
        where: pc.program_id == ^program_id,
        select: pc.course_id
      )
      |> Repo.all()
    
    from(c in Course,
      where: c.id not in ^assigned_course_ids,
      where: c.is_active == true
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
end
