defmodule Register.Attendance do
  @moduledoc """
  Attendance context for computing student attendance summaries.
  This initial version derives structure from enrolled courses.
  """

  alias Register.Academic

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
end
