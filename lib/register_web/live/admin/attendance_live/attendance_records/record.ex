defmodule RegisterWeb.Admin.AttendanceLive.AttendanceRecords.Record do
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
      |> assign(:attendance_data, %{})
      |> assign(:loading, false)
      |> assign(:search_query, "")
      |> assign(:filtered_students, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :record, _params) do
    socket
    |> assign(:page_title, "Record Attendance")
  end

  @impl true
  def handle_event("select_program", %{"program_id" => program_id}, socket) do
    program = Academic.get_program!(program_id)
    students = Academic.list_program_students(program.id)

    socket =
      socket
      |> assign(:selected_program, program)
      |> assign(:students, students)
      |> assign(:filtered_students, students)
      |> assign(:selected_course, nil)
      |> assign(:courses, [])

    {:noreply, socket}
  end

  def handle_event("select_course", %{"course_id" => course_id}, socket) do
    course = Courses.get_course!(course_id)
    students = Academic.list_course_students(course.id)

    attendance_data =
      students
      |> Enum.map(fn student ->
        {student.id, %{present: false, marked: false}}
      end)
      |> Map.new()

    socket =
      socket
      |> assign(:selected_course, course)
      |> assign(:students, students)
      |> assign(:filtered_students, students)
      |> assign(:attendance_data, attendance_data)

    {:noreply, socket}
  end

  def handle_event("search_students", %{"query" => query}, socket) do
    filtered_students =
      if query == "" do
        socket.assigns.students
      else
        search_query = String.downcase(query)
        Enum.filter(socket.assigns.students, fn student ->
          String.contains?(String.downcase("#{student.first_name} #{student.last_name}"), search_query) ||
          String.contains?(String.downcase(student.email), search_query)
        end)
      end

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:filtered_students, filtered_students)}
  end

  def handle_event("toggle_attendance", %{"student_id" => student_id}, socket) do
    current_data = socket.assigns.attendance_data
    student_data = Map.get(current_data, String.to_integer(student_id), %{present: false, marked: false})

    updated_data =
      Map.put(current_data, String.to_integer(student_id), %{
        present: !student_data.present,
        marked: true
      })

    {:noreply, assign(socket, :attendance_data, updated_data)}
  end

  def handle_event("mark_all_present", _params, socket) do
    attendance_data =
      socket.assigns.students
      |> Enum.map(fn student ->
        {student.id, %{present: true, marked: true}}
      end)
      |> Map.new()

    {:noreply, assign(socket, :attendance_data, attendance_data)}
  end

  def handle_event("mark_all_absent", _params, socket) do
    attendance_data =
      socket.assigns.students
      |> Enum.map(fn student ->
        {student.id, %{present: false, marked: true}}
      end)
      |> Map.new()

    {:noreply, assign(socket, :attendance_data, attendance_data)}
  end

  def handle_event("save_attendance", _params, socket) do
    socket = assign(socket, :loading, true)

    case save_attendance_records(socket) do
      {:ok, _count} ->
        socket =
          socket
          |> put_flash(:info, "Attendance saved successfully!")
          |> assign(:loading, false)
          |> assign(:attendance_data, %{})

        {:noreply, socket}

      {:error, _reason} ->
        socket =
          socket
          |> put_flash(:error, "Failed to save attendance")
          |> assign(:loading, false)

        {:noreply, socket}
    end
  end

  defp save_attendance_records(socket) do
    course = socket.assigns.selected_course
    attendance_data = socket.assigns.attendance_data

    results =
      attendance_data
      |> Enum.filter(fn {_student_id, data} -> data.marked end)
      |> Enum.map(fn {student_id, data} ->
        if data.present do
          Attendance.record_attendance(
            student_id,
            course.id,
            course.code,
            course.title,
            Date.utc_today(),
            %{method: "manual"}
          )
        else
          # Record as absent - could create absent records if needed
          {:ok, nil}
        end
      end)

    # Check if all operations were successful
    case Enum.find(results, fn result -> match?({:error, _}, result) end) do
      nil -> {:ok, length(results)}
      error -> error
    end
  end

  defp get_student_attendance_status(student_id, attendance_data) do
    case Map.get(attendance_data, student_id) do
      %{present: true} -> "present"
      %{present: false} -> "absent"
      _ -> "not_marked"
    end
  end

  defp format_student_name(student) do
    "#{student.first_name} #{student.last_name}"
  end
end
