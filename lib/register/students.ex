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
  Gets a student by user ID.

  ## Examples

      iex> get_student_by_user_id(123)
      %Student{}

      iex> get_student_by_user_id(999)
      nil
  """
  def get_student_by_user_id(id) do
    Repo.get_by(Student, user_id: id)
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
        password = Map.get(attrs, :password) || Map.get(attrs, "password") || generate_temp_password()

        email = Map.get(attrs, :email) || Map.get(attrs, "email")
        name = Map.get(attrs, :name) || Map.get(attrs, "name") || "Student"

        # Register user account linked to student
        user_attrs = %{
          email: email,
          password: password,
          role: "student",
          first_name: student.first_name,
          last_name: student.last_name
        }

        case Register.Accounts.create_user_with_role(user_attrs, "student") do
          {:ok, _user} ->
            {:ok, student}

          {:error, changeset} ->
            # Rollback student creation if user registration fails
            Repo.delete(student)
            {:error, changeset}
        end

      error -> error
    end
  end

  defp generate_temp_password() do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, 16)
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
    # Delete associated user if it exists
    if user = Register.Accounts.get_user_by_email(student.email) do
      Repo.delete(user)
    end
    
    # Delete the student
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
