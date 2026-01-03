defmodule Register.Dockets do
  @moduledoc """
  The Dockets context handles docket generation for students.
  """

  import Ecto.Query, warn: false
  alias Register.Repo
  alias Register.Academic
  alias Register.Accounts

  @doc """
  Gets student information with their program details.
  """
  def get_student_info(user_id) do
    try do
      user = Accounts.get_user!(user_id)

      student_program =
        from(sp in Register.Academic.StudentProgram,
          where: sp.student_id == ^user_id and sp.is_active == true,
          preload: [:program],
          limit: 1
        )
        |> Repo.one()

      if student_program do
        {:ok, user, student_program}
      else
        {:error, :no_program}
      end
    rescue
      _e -> {:error, :not_found}
    end
  end

  @doc """
  Gets all courses for a student for a specific docket type.
  """
  def get_docket_courses(user_id, docket_type \\ "exam") do
    courses = Academic.list_student_courses(user_id)

    case docket_type do
      "cat1" ->
        Enum.filter(courses, fn %{semester: sem} -> sem == 1 end)

      "cat2" ->
        Enum.filter(courses, fn %{semester: sem} -> sem == 2 end)

      "exam" ->
        courses

      _ ->
        courses
    end
  end

  @doc """
  Generates docket HTML for download/viewing.
  """
  def generate_docket_html(user_id, docket_type, logo_url) do
    case get_student_info(user_id) do
      {:ok, user, student_program} ->
        courses = get_docket_courses(user_id, docket_type)

        {:ok,
         %{
           user: user,
           student_program: student_program,
           courses: courses,
           docket_type: docket_type,
           logo_url: logo_url,
           document_id: generate_document_id(user_id),
           date_issued: Date.utc_today()
         }}

      error ->
        error
    end
  end

  @doc """
  Generates a unique document ID for the docket.
  """
  def generate_document_id(user_id) do
    timestamp = System.system_time(:millisecond)
    "#{timestamp}#{user_id}#{Enum.random(1000..9999)}"
  end

  @doc """
  Gets the docket type display name.
  """
  def docket_type_name("cat1"), do: "CAT 1 Docket"
  def docket_type_name("cat2"), do: "CAT 2 Docket"
  def docket_type_name("exam"), do: "Exam Docket"
  def docket_type_name(_), do: "Docket"

  @doc """
  Gets the semester for a given docket type.
  """
  def get_semester_info("cat1"), do: "Semester 1"
  def get_semester_info("cat2"), do: "Semester 2"
  def get_semester_info("exam"), do: "Semester: 2026 - Jul - Semester 4"
  def get_semester_info(_), do: "Academic Semester"
end
