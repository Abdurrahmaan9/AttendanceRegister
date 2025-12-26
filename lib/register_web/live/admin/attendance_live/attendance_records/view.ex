defmodule RegisterWeb.Admin.AttendanceLive.AttendanceRecords.View do
  use RegisterWeb, :live_view

  alias Register.Attendance
  alias Register.Academic
  alias Register.Accounts
  alias Register.Courses

  @impl true
  def mount(_params, _session, socket) do
    programs = Academic.list_programs()
    courses = Courses.list_courses()

    socket =
      socket
      |> assign(:programs, programs)
      |> assign(:courses, courses)
      |> assign(:selected_program, nil)
      |> assign(:selected_course, nil)
      |> assign(:students, [])
      |> assign(:attendance_summaries, %{})
      |> assign(:overall_stats, %{})

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :view, _params) do
    socket
    |> assign(:page_title, "View Attendance")
  end

  @impl true
  def handle_event("select_program", %{"program_id" => program_id}, socket) do
    program = Academic.get_program!(program_id)
    students = Academic.list_program_students(program.id)

    attendance_summaries =
      students
      |> Enum.map(fn student ->
        summary = Attendance.student_attendance_summary(student.id)
        {student.id, summary}
      end)
      |> Map.new()

    overall_stats = calculate_overall_stats(attendance_summaries)

    socket =
      socket
      |> assign(:selected_program, program)
      |> assign(:students, students)
      |> assign(:selected_course, nil)
      |> assign(:attendance_summaries, attendance_summaries)
      |> assign(:overall_stats, overall_stats)

    {:noreply, socket}
  end

  def handle_event("select_course", %{"course_id" => course_id}, socket) do
    course = Courses.get_course!(course_id)
    students = Academic.list_course_students(course.id)

    attendance_summaries =
      students
      |> Enum.map(fn student ->
        summary = Attendance.student_attendance_summary(student.id)
        {student.id, summary}
      end)
      |> Map.new()

    overall_stats = calculate_overall_stats(attendance_summaries)

    socket =
      socket
      |> assign(:selected_course, course)
      |> assign(:students, students)
      |> assign(:attendance_summaries, attendance_summaries)
      |> assign(:overall_stats, overall_stats)

    {:noreply, socket}
  end

  def handle_event("refresh_data", _params, socket) do
    # Refresh attendance data for current selection
    socket =
      if socket.assigns.selected_course do
        handle_event("select_course", %{"course_id" => socket.assigns.selected_course.id}, socket)
      else
        handle_event("select_program", %{"program_id" => socket.assigns.selected_program.id}, socket)
      end

    {:noreply, put_flash(socket, :info, "Attendance data refreshed!")}
  end

  defp calculate_overall_stats(attendance_summaries) do
    summaries = Map.values(attendance_summaries)

    total_students = length(summaries)

    if total_students > 0 do
      total_sessions = Enum.sum(Enum.map(summaries, & &1.total_sessions))
      total_attended = Enum.sum(Enum.map(summaries, & &1.attended_sessions))
      total_missed = Enum.sum(Enum.map(summaries, & &1.missed_sessions))

      overall_rate = if total_sessions > 0 do
        (total_attended / total_sessions) * 100
      else
        0.0
      end

      # Calculate attendance distribution
      attendance_distribution =
        summaries
        |> Enum.map(fn summary -> summary.attendance_rate end)
        |> calculate_distribution()

      %{
        total_students: total_students,
        total_sessions: total_sessions,
        total_attended: total_attended,
        total_missed: total_missed,
        overall_rate: Float.round(overall_rate, 2),
        distribution: attendance_distribution
      }
    else
      %{
        total_students: 0,
        total_sessions: 0,
        total_attended: 0,
        total_missed: 0,
        overall_rate: 0.0,
        distribution: %{excellent: 0, good: 0, average: 0, poor: 0}
      }
    end
  end

  defp calculate_distribution(rates) do
    Enum.reduce(rates, %{excellent: 0, good: 0, average: 0, poor: 0}, fn rate, acc ->
      cond do
        rate >= 95 -> %{acc | excellent: acc.excellent + 1}
        rate >= 85 -> %{acc | good: acc.good + 1}
        rate >= 75 -> %{acc | average: acc.average + 1}
        true -> %{acc | poor: acc.poor + 1}
      end
    end)
  end

  defp get_attendance_color(rate) do
    cond do
      rate >= 95 -> "text-green-600 bg-green-100"
      rate >= 85 -> "text-blue-600 bg-blue-100"
      rate >= 75 -> "text-yellow-600 bg-yellow-100"
      true -> "text-red-600 bg-red-100"
    end
  end

  defp get_attendance_label(rate) do
    cond do
      rate >= 95 -> "Excellent"
      rate >= 85 -> "Good"
      rate >= 75 -> "Average"
      true -> "Poor"
    end
  end
end
