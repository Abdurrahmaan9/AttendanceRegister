defmodule Register.Attendance do
  @moduledoc """
  Attendance context for computing student attendance summaries.
  This initial version derives structure from enrolled courses.
  """

  import Ecto.Query, warn: false
  alias Register.Academic
  alias Register.Attendance.AttendanceRecord
  alias Register.Repo
  alias Register.Accounts

  def student_attendance_summary(student_id) do
    courses = Academic.list_student_courses(student_id)

    %{
      total_courses: length(courses),
      total_sessions: 0,
      attended_sessions: 0,
      missed_sessions: 0,
      attendance_rate: 0.0,
      per_course:
        Enum.map(courses, fn %{course: course} ->
          %{
            course: course,
            sessions: 0,
            attended: 0,
            missed: 0,
            rate: 0.0
          }
        end)
    }
  end

  # Lists recent scans for a lecturer's generated QR/OTP sessions.
  # Placeholder until scan logging is implemented.
  def list_recent_scans_for_lecturer(_lecturer_id) do
    %{
      total_scans: 0,
      sessions: []
    }
  end

  # Admin overview filtered by program and/or course/module.
  # Placeholder implementation until scan logging is implemented.
  def admin_attendance_summary(%{program_id: program_id, course_id: course_id}) do
    %{
      filter: %{program_id: program_id, course_id: course_id},
      total_sessions: 0,
      total_students: 0,
      attended: 0,
      missed: 0,
      attendance_rate: 0.0,
      sessions: []
    }
  end

  def record_attendance(student_id, course_id, module_code, module_name, session_date, attrs) do
    user = Accounts.get_user!(student_id)
    first_name = attrs[:first_name] || user.first_name || ""
    last_name = attrs[:last_name] || user.last_name || ""

    {first_name, last_name} =
      case {String.trim(first_name), String.trim(last_name)} do
        {"", ""} ->
          local = String.split(user.email || "", "@") |> List.first() || ""
          parts = Regex.split(~r/[._-]+/, local, trim: true)
          case parts do
            [p1, p2 | _] -> {String.capitalize(p1), String.capitalize(p2)}
            [p1] -> {String.capitalize(p1), ""}
            _ -> {"", ""}
          end
        {f, l} -> {f, l}
      end

    # Prevent duplicates: one attendance per student per course per session_date
    dup? =
      from(ar in AttendanceRecord,
        where:
          ar.student_id == ^student_id and
          ar.course_id == ^course_id and
          ar.module_code == ^module_code and
          ar.session_date == ^session_date
      )
      |> Repo.exists?()

    if dup? do
      {:error, :already_marked}
    else
      changeset = AttendanceRecord.changeset(%AttendanceRecord{}, %{
        student_id: student_id,
        first_name: first_name,
        last_name: last_name,
        course_id: course_id,
        module_code: module_code,
        module_name: module_name,
        session_date: session_date,
        method: attrs[:method] || "otp"
      })

      case Repo.insert(changeset) do
        {:ok, record} -> {:ok, record}
        {:error, %Ecto.Changeset{} = changeset} ->
          # If the DB unique index is hit, the unique_constraint in the changeset
          # will surface a friendly message. Convert to {:error, :already_marked}
          if Enum.any?(changeset.errors, fn {_field, {msg, _opts}} ->
               msg == "attendance already recorded for this session"
             end) do
            {:error, :already_marked}
          else
            {:error, changeset}
          end
      end
    end
  end
end
