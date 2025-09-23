defmodule Register.Courses do
  @moduledoc """
  The Courses context.
  """

  import Ecto.Query, warn: false
  alias Register.Repo
  alias Register.Courses.Course
  alias Register.Academic.ProgramCourse

  @doc """
  Returns the list of courses.

  ## Examples

      iex> list_courses()
      [%Course{}, ...]

  """
  def list_courses do
    from(c in Course, where: c.is_active == true, order_by: [asc: :code])
    |> Repo.all()
  end

  @doc """
  Lists all courses including inactive ones.
  """
  def list_all_courses do
    from(c in Course, order_by: [asc: :code])
    |> Repo.all()
  end

  @doc """
  Gets a single course.

  Raises `Ecto.NoResultsError` if the Course does not exist.

  ## Examples

      iex> get_course!(123)
      %Course{}

      iex> get_course!(456)
      ** (Ecto.NoResultsError)

  """
  def get_course!(id) do
    Course
    |> Repo.get!(id)
    |> Repo.preload([:programs, program_courses: :program])
  end

  @doc """
  Creates a course.

  ## Examples

      iex> create_course(%{field: value})
      {:ok, %Course{}}

      iex> create_course(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_course(attrs \\ %{}) do
    %Course{}
    |> Course.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a course.

  ## Examples

      iex> update_course(course, %{field: new_value})
      {:ok, %Course{}}

      iex> update_course(course, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_course(%Course{} = course, attrs) do
    course
    |> Course.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a course.

  ## Examples

      iex> delete_course(course)
      {:ok, %Course{}}

      iex> delete_course(course)
      {:error, %Ecto.Changeset{}}

  """
  def delete_course(%Course{} = course) do
    Repo.delete(course)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking course changes.

  ## Examples

      iex> change_course(course)
      %Ecto.Changeset{data: %Course{}}

  """
  def change_course(%Course{} = course, attrs \\ %{}) do
    Course.changeset(course, attrs)
  end

  @doc """
  Lists courses not assigned to a specific program.
  """
  def list_available_courses(program_id) do
    assigned_course_ids =
      from(pc in ProgramCourse,
        where: pc.program_id == ^program_id,
        select: pc.course_id
      )
      |> Repo.all()

    from(c in Course,
      where: c.id not in ^assigned_course_ids,
      where: c.is_active == true,
      order_by: [asc: :code]
    )
    |> Repo.all()
  end

  @doc """
  Gets courses by program, year, and semester.
  """
  def get_courses_by_program_and_semester(program_id, year, semester) do
    from(pc in ProgramCourse,
      where: pc.program_id == ^program_id and pc.year == ^year and pc.semester == ^semester,
      where: pc.is_active == true,
      preload: [:course],
      order_by: [asc: :is_core, asc: :id]
    )
    |> Repo.all()
    |> Enum.map(fn pc -> %{pc.course | program_course_id: pc.id, is_core: pc.is_core} end)
  end

  @doc """
  Returns the total count of courses.

  ## Examples

      iex> count_courses()
      5

  """
  def count_courses do
    Repo.aggregate(Course, :count, :id)
  end
end
