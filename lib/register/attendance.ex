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
  alias Register.Otps.Otp
  alias Register.Attendance.SummaryHelper
  alias Register.Attendance.SummaryCache

  def student_attendance_summary(student_id) do
    case SummaryCache.get(student_id) do
      {:ok, summary} -> summary
      :miss ->
        summary = compute_attendance_summary(student_id)
        SummaryCache.put(student_id, summary)
        summary
    end
  end

  def compute_attendance_summary(student_id) do
    courses = Academic.list_student_courses(student_id)

    per_course =
      Enum.map(courses, fn %{course: course} = info ->
        module_code = course.code
        course_id = course.id

        total_sessions =
          from(o in Otp,
            where: o.course_id == ^course_id and o.module_code == ^module_code
          )
          |> Repo.aggregate(:count, :id)

        attended =
          from(ar in AttendanceRecord,
            where:
              ar.student_id == ^student_id and
              ar.course_id == ^course_id and
              ar.module_code == ^module_code
          )
          |> Repo.aggregate(:count, :id)

        missed = max(total_sessions - attended, 0)
        rate = SummaryHelper.rate(attended, total_sessions)

        %{
          course: course,
          year: Map.get(info, :year),
          semester: Map.get(info, :semester),
          sessions: total_sessions,
          attended: attended,
          missed: missed,
          rate: rate
        }
      end)

    total_sessions = Enum.reduce(per_course, 0, fn m, acc -> acc + m.sessions end)
    attended_sessions = Enum.reduce(per_course, 0, fn m, acc -> acc + m.attended end)
    missed_sessions = Enum.reduce(per_course, 0, fn m, acc -> acc + m.missed end)

    %{
      total_courses: length(courses),
      total_sessions: total_sessions,
      attended_sessions: attended_sessions,
      missed_sessions: missed_sessions,
      attendance_rate: SummaryHelper.rate(attended_sessions, total_sessions),
      per_course: per_course
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

  @doc """
  Fetches attendance statistics for admin view, filtered by program and/or course.
  """
  def admin_attendance_summary(%{program_id: program_id, course_id: course_id}) do
    # Get all courses for the selected program if program_id is provided
    course_ids =
      if program_id do
        from(pc in "program_courses",
          where: pc.program_id == ^program_id,
          select: pc.course_id
        )
        |> Repo.all()
      else
        []
      end

    # Base query for attendance records
    attendance_query = from(ar in "attendance_records", as: :ar)

    # Apply program filter (if any program courses found)
    attendance_query =
      if program_id && !Enum.empty?(course_ids) do
        from(ar in attendance_query, where: ar.course_id in ^course_ids)
      else
        attendance_query
      end

    # Apply course filter if provided (takes precedence over program filter)
    attendance_query = if course_id do
      from(ar in attendance_query, where: ar.course_id == ^course_id)
    else
      attendance_query
    end

    # Get all unique sessions with attendance counts
    sessions =
      attendance_query
      |> join(:left, [ar: ar], c in "courses", on: c.id == ar.course_id, as: :c)
      |> group_by([ar: ar, c: c], [ar.course_id, ar.module_code, ar.session_date, c.title])
      |> select([ar: ar, c: c], %{
        course_id: ar.course_id,
        course_name: c.title,
        module_code: ar.module_code,
        session_date: ar.session_date,
        attended: count(ar.id)
      })
      |> Repo.all()

    # Calculate total sessions (unique module + date combinations)
    total_sessions =
      attendance_query
      |> distinct([ar: ar], [ar.course_id, ar.module_code, ar.session_date])
      |> Repo.aggregate(:count, :id)

    # Calculate total attendance
    total_attended = Enum.sum(Enum.map(sessions, & &1.attended))

    # Get unique students based on filters
    total_students =
      cond do
        # If course is selected, get students who attended that course
        course_id ->
          from(ar in "attendance_records",
            where: ar.course_id == ^course_id,
            select: count(ar.student_id, :distinct)
          )
          |> Repo.one() || 0

        # If program is selected, get students enrolled in that program
        program_id && !Enum.empty?(course_ids) ->
          from(sp in "student_programs",
            where: sp.program_id == ^program_id and sp.is_active == true,
            select: count(sp.student_id, :distinct)
          )
          |> Repo.one() || 0

        # Otherwise, get all active students
        true ->
          from(u in Register.Accounts.User,
            where: u.role == "student" and u.is_active == true
          )
          |> Repo.aggregate(:count, :id) || 0
      end

    # Calculate attendance statistics
    {total_missed, attendance_rate} =
      if total_students > 0 and total_sessions > 0 do
        total_possible = total_sessions * total_students
        missed = max(total_possible - total_attended, 0)
        rate = (total_attended / total_possible) * 100
        {missed, rate}
      else
        {0, 0.0}
      end

    %{
      filter: %{program_id: program_id, course_id: course_id},
      total_sessions: total_sessions,
      total_students: total_students,
      attended: total_attended,
      missed: total_missed,
      attendance_rate: Float.round(attendance_rate, 2),
      sessions: sessions
    }
  end

  @doc """
  Returns attendance summary for a lecturer's courses.
  """
  def lecturer_attendance_summary(%{lecturer_id: lecturer_id, course_id: course_id}) do
    # Get all courses for the lecturer if no specific course is selected
    courses =
      if course_id do
        [Register.Courses.get_course!(course_id)]
      else
        Register.Academic.list_lecturer_courses(lecturer_id)
      end

    # Calculate statistics for each course
    per_course =
      courses
      |> Enum.map(fn course ->
        module_code = course.code

        # Get total number of sessions for this course
        total_sessions =
          from(o in Otp,
            where: o.course_id == ^course.id and o.module_code == ^module_code,
            select: count(o.id)
          )
          |> Repo.one()

        # Get total attendance for this course
        total_attendance =
          from(ar in AttendanceRecord,
            where: ar.course_id == ^course.id and ar.module_code == ^module_code,
            select: count(ar.id)
          )
          |> Repo.one()

        # Get unique students who attended
        unique_students =
          from(ar in AttendanceRecord,
            where: ar.course_id == ^course.id and ar.module_code == ^module_code,
            select: fragment("COUNT(DISTINCT ?)", ar.student_id)
          )
          |> Repo.one() || 0

        # Get attendance by method (QR vs OTP)
        qr_attendance =
          from(ar in AttendanceRecord,
            where: ar.course_id == ^course.id and ar.module_code == ^module_code and ar.method == "qr",
            select: count(ar.id)
          )
          |> Repo.one()

        otp_attendance = total_attendance - qr_attendance

        %{
          course_id: course.id,
          module_code: module_code,
          title: course.title,
          total_sessions: total_attendance,
          unique_students: unique_students,
          total_attendance: total_attendance,
          qr_attendance: qr_attendance,
          otp_attendance: otp_attendance
        }
      end)

    # Calculate overall statistics
    total_sessions = Enum.reduce(per_course, 0, &(&2 + &1.total_sessions))
    total_attendance = Enum.reduce(per_course, 0, &(&2 + &1.total_attendance))
    unique_students =
      per_course
      |> Enum.flat_map(fn c -> [c.unique_students] end)
      |> Enum.uniq()
      |> length()

    %{
      per_course: per_course,
      total_courses: length(per_course),
      total_sessions: total_sessions,
      total_attendance: total_attendance,
      unique_students: unique_students,
      sessions: list_recent_sessions(lecturer_id, course_id)
    }
  end

  defp list_recent_sessions(lecturer_id, course_id) do
    base_query =
      from(ar in AttendanceRecord,
        join: o in Otp, on: o.course_id == ar.course_id and o.module_code == ar.module_code,
        where: o.created_by_id == ^lecturer_id,
        preload: [:course],
        order_by: [desc: ar.inserted_at],
        limit: 10
      )

    query =
      if course_id do
        from(ar in base_query, where: ar.course_id == ^course_id)
      else
        base_query
      end

    # Get records with preloaded course
    records = Repo.all(query)

    # Transform records to include all necessary fields
    Enum.map(records, fn ar ->
      %{
        id: ar.id,
        module_code: ar.module_code,
        module_name: ar.module_name,
        inserted_at: ar.inserted_at,
        method: ar.method,
        first_name: ar.first_name,
        last_name: ar.last_name,
        course: %{
          id: ar.course.id,
          title: ar.course.title,
          code: ar.course.code
        },
        student_name: "#{ar.first_name} #{ar.last_name}",
        type: ar.method,
        title: ar.module_name
      }
    end)
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
        {:ok, record} ->
          # Refresh cached summary so dashboards update immediately
          SummaryCache.refresh_student(student_id)
          {:ok, record}
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

  @doc """
  Gets attendance statistics for a specific module code, combining both QR code and OTP records.
  Groups by both module_code and session_date to ensure accurate session tracking.
  """
  def get_module_stats(module_code) when is_binary(module_code) do
    # Get all attendance records for this module from both QR codes and OTPs
    records = from(ar in "attendance_records",
      where: ar.module_code == ^module_code,
      select: %{
        id: ar.id,
        student_id: ar.student_id,
        first_name: ar.first_name,
        last_name: ar.last_name,
        session_date: ar.session_date,
        source: fragment("CASE WHEN qr_code_id IS NOT NULL THEN 'qr' ELSE 'otp' END")
      }
    ) |> Repo.all()

    # Group by session date to identify unique sessions
    sessions_by_date = Enum.group_by(records, & &1.session_date)

    # Calculate stats
    total_sessions = map_size(sessions_by_date)

    # Get unique students who attended this module (regardless of source)
    unique_students = records
      |> Enum.uniq_by(& &1.student_id)
      |> length()

    # Get attendance per session with source information
    attendance_per_session = Enum.map(sessions_by_date, fn {date, records} ->
      # Group by source (qr/otp) for this session date
      by_source = Enum.group_by(records, & &1.source)

      %{
        date: date,
        count: length(records),
        qr_attendance: length(Map.get(by_source, "qr", [])),
        otp_attendance: length(Map.get(by_source, "otp", [])),
        students: records
          |> Enum.uniq_by(& &1.student_id)
          |> Enum.map(&%{
            id: &1.student_id,
            name: "#{&1.first_name} #{&1.last_name}",
            source: &1.source
          })
      }
    end) |> Enum.sort_by(& &1.date, {:desc, Date})

    # Calculate total attendance (unique student-session pairs)
    total_attendance = records
      |> Enum.uniq_by(fn r -> {r.student_id, r.session_date} end)
      |> length()

    %{
      module_code: module_code,
      total_sessions: total_sessions,
      unique_students: unique_students,
      total_attendance: total_attendance,
      attendance_per_session: attendance_per_session
    }
  end

  def total_classes_for_day do
    beginning_of_day = Date.utc_today()

    query = from a in "attendance_records",
      where: a.session_date >= ^beginning_of_day,
      select: count(a.id)

    Repo.one(query) || 0
  end

  @doc """
  Returns paginated recent activities across the system.

  ## Parameters

  - page: Page number (default: 1)
  - per_page: Items per page (default: 10)

  ## Returns

  {activities, pagination_info}
  """
  def list_recent_activities_paginated(page \\ 1, per_page \\ 10) do
    page = max(page, 1)
    per_page = max(per_page, 1)

    # Get recent attendance records
    attendance_query = from(a in "attendance_records",
      join: u in "users", on: a.student_id == u.id,
      select: %{
        type: "attendance",
        user_name: fragment("? || ' ' || ?", u.first_name, u.last_name),
        user_email: u.email,
        action: "marked attendance",
        target: a.module_name,
        timestamp: a.inserted_at,
        details: a.method
      })

    # Get recent QR codes created
    qr_query = from(q in "qr_codes",
      join: u in "users", on: q.created_by_id == u.id,
      select: %{
        type: "qr_code",
        user_name: fragment("? || ' ' || ?", u.first_name, u.last_name),
        user_email: u.email,
        action: "created QR code",
        target: q.name,
        timestamp: q.inserted_at,
        details: q.class_name
      })

    # Get recent OTPs generated
    otp_query = from(o in "otp",
      join: u in "users", on: o.created_by_id == u.id,
      select: %{
        type: "otp",
        user_name: fragment("? || ' ' || ?", u.first_name, u.last_name),
        user_email: u.email,
        action: "generated OTP",
        target: o.course_name,
        timestamp: o.inserted_at,
        details: o.session_date
      })

    # Execute queries separately and combine in memory
    attendance_activities = Repo.all(attendance_query)
    qr_activities = Repo.all(qr_query)
    otp_activities = Repo.all(otp_query)

    # Combine and sort all activities
    all_activities = attendance_activities ++ qr_activities ++ otp_activities
      |> Enum.sort_by(fn activity ->
        case activity.timestamp do
          %DateTime{} -> activity.timestamp
          %NaiveDateTime{} -> DateTime.from_naive!(activity.timestamp, "Etc/UTC")
          _ -> DateTime.utc_now()
        end
      end, {:desc, DateTime})

    # Get total count
    total_entries = length(all_activities)
    total_pages = ceil(total_entries / per_page)

    # Paginate the combined results
    activities = all_activities
      |> Enum.drop((page - 1) * per_page)
      |> Enum.take(per_page)

    pagination_info = %{
      current_page: page,
      per_page: per_page,
      total_pages: total_pages,
      total_entries: total_entries,
      has_next_page: page < total_pages,
      has_prev_page: page > 1
    }

    {activities, pagination_info}
  end
end
