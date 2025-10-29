defmodule Register.Students do
  @moduledoc """
  The Students context.
  """

  import Ecto.Query, warn: false
  alias Register.Repo
  alias Register.Students.Student

  @doc """
  Returns the list of students.

  ## Examples

      iex> list_students()
      [%Student{}, ...]

  """
  def list_students do
    Repo.all(Student)
  end

  @doc """
  Returns the total count of students.

  ## Examples

      iex> count_students()
      42

  """
  def count_students do
    Repo.aggregate(Student, :count, :id)
  end

  @doc """
  Gets a single student.

  Raises `Ecto.NoResultsError` if the Student does not exist.

  ## Examples

      iex> get_student!(123)
      %Student{}

      iex> get_student!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student!(id), do: Repo.get!(Student, id)

  @doc """
  Gets a single student by email.

  Returns nil if the Student does not exist.

  ## Examples

      iex> get_student_by_email("user@example.com")
      %Student{}

      iex> get_student_by_email("nonexistent@example.com")
      nil

  """
  def get_student_by_email(email) do
    Repo.get_by(Student, email: email)
  end

  @doc """
  Creates a student and registers a user account with a random password.

  ## Examples

      iex> create_student(%{field: value, email: "user@example.com"})
      {:ok, %Student{}}

      iex> create_student(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def create_student(attrs \\ %{}) do
    # Create student
    case %Student{} |> Student.changeset(attrs) |> Repo.insert() do
      {:ok, student} ->
        # Generate random password
        password = :crypto.strong_rand_bytes(8) |> Base.encode64() |> binary_part(0, 12)

        email = Map.get(attrs, :email) || Map.get(attrs, "email")
        name = Map.get(attrs, :name) || Map.get(attrs, "name") || "Student"

        # Register user account linked to student
        user_attrs = %{email: email, password: password, role: "student"}

        case Register.Accounts.register_user(user_attrs) do
          {:ok, _user} ->
            # Send welcome email with credentials
            Task.start(fn ->
              Register.Emails.send_welcome_email(email, name, password)
            end)
            {:ok, student}

          {:error, changeset} ->
            # Rollback student creation if user registration fails
            Repo.delete(student)
            {:error, changeset}
        end

      error -> error
    end
  end

  @doc """
  Updates a student.

  ## Examples

      iex> update_student(student, %{field: new_value})
      {:ok, %Student{}}

      iex> update_student(student, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student(%Student{} = student, attrs) do
    student
    |> Student.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student.

  ## Examples

      iex> delete_student(student)
      {:ok, %Student{}}

      iex> delete_student(student)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student(%Student{} = student) do
    Repo.delete(student)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student changes.

  ## Examples

      iex> change_student(student)
      %Ecto.Changeset{data: %Student{}}

  """
  def change_student(%Student{} = student, attrs \\ %{}) do
    Student.changeset(student, attrs)
  end
end
