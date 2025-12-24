defmodule RegisterWeb.Admin.Dashboard.Index do
  use RegisterWeb, :live_view
  alias Register.Students
  alias Register.Accounts
  alias Register.Attendance
  alias Register.Accounts.User
  alias Register.Repo
  import Ecto.Query
  # alias RegisterWeb.Helpers.RoleHelper

  # Import the role helper functions
  # import RegisterWeb.Helpers.RoleHelper, only: [role_class: 1]

  @url "/Admin/dashboard"
  @sample_interval 5_000
  @max_points 20

  @impl true
  def mount(params, session, socket) do
    current_user = get_session_user(session)

    # Get pagination parameters
    page = String.to_integer(params["page"] || "1")
    per_page = String.to_integer(params["per_page"] || "10")

    total_students = Students.count_students()
    total_staff = Accounts.total_users_by_roles(["lecturer", "admin", "staff"])
    total_sessions_for_day = Attendance.total_classes_for_day()
    total_courses = count_courses()
    total_programs = count_programs()
    total_qr_codes = count_qr_codes()
    total_otps = count_otps()
    today_attendance = count_today_attendance()
    students_per_course = get_students_per_course()
    {recent_activities, pagination_info} = Attendance.list_recent_activities_paginated(page, per_page)

    socket =
      socket
      |> assign(:current_path, @url)
      |> assign(:sidebar_open, false)
      |> assign(:current_user, current_user)
      |> assign(:total_students, total_students)
      |> assign(:total_staff, total_staff)
      |> assign(:total_sessions_for_day, total_sessions_for_day)
      |> assign(:total_courses, total_courses)
      |> assign(:total_programs, total_programs)
      |> assign(:total_qr_codes, total_qr_codes)
      |> assign(:total_otps, total_otps)
      |> assign(:today_attendance, today_attendance)
      |> assign(:students_per_course, students_per_course)
      |> assign(:recent_activities, recent_activities)
      |> assign(:pagination_info, pagination_info)
      |> assign_new(:metrics, fn -> initial_metrics() end)
      |> assign_stats()
      |> assign_initial_system_metrics()

    if connected?(socket) and current_user do
      # Subscribe to admin dashboard updates
      if current_user.role == "admin" do
        RegisterWeb.Endpoint.subscribe("admin_dashboard:#{current_user.id}")
      end

      # Only update system metrics every 30 seconds
      :timer.send_interval(60_000, :sample_system_metrics)
      # Also do an initial sample to populate charts immediately
      {:ok, sample_and_assign(socket)}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    # Get pagination parameters from URL
    page = String.to_integer(params["page"] || "1")
    per_page = String.to_integer(params["per_page"] || "10")

    # Get paginated recent activities from context
    {recent_activities, pagination_info} = Attendance.list_recent_activities_paginated(page, per_page)

    socket =
      socket
      |> assign(:recent_activities, recent_activities)
      |> assign(:pagination_info, pagination_info)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page, "per-page" => per_page}, socket) do
    page = String.to_integer(page)
    per_page = String.to_integer(per_page)

    {recent_activities, pagination_info} = Attendance.list_recent_activities_paginated(page, per_page)

    socket =
      socket
      |> assign(:recent_activities, recent_activities)
      |> assign(:pagination_info, pagination_info)
      |> push_patch(to: "#{@url}?page=#{page}&per_page=#{per_page}")

    {:noreply, socket}
  end

  @impl true
  def handle_info(:sample_system_metrics, socket) do
    # Only update system metrics, not attendance data
    {:noreply, sample_and_assign(socket)}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{topic: "admin_dashboard:" <> _, event: "attendance_update", payload: attendance_data}, socket) do
    # Handle attendance updates from background job
    socket =
      socket
      |> assign(:daily_labels, attendance_data.daily_labels)
      |> assign(:daily_qr_data, attendance_data.daily_qr_data)
      |> assign(:daily_otp_data, attendance_data.daily_otp_data)
      |> assign(:weekly_trend_labels, attendance_data.weekly_trend_labels)
      |> assign(:weekly_trend_data, attendance_data.weekly_trend_data)
      |> assign(:signin_qr, attendance_data.signin_qr)
      |> assign(:signin_otp, attendance_data.signin_otp)

    {:noreply, socket}
  end

  defp get_session_user(session) do
    case session["user_token"] do
      nil -> nil
      token -> Register.Accounts.get_user_by_session_token(token)
    end
  end

  defp sample_and_assign(socket) do
    metrics = socket.assigns.metrics
    new_metrics = collect_metrics(metrics)

    socket
    |> assign(:metrics, new_metrics)
    |> assign(:uptime_min, new_metrics.uptime_min)
    |> assign(:memory_mb, new_metrics.memory_mb)
    |> assign(:run_queue, new_metrics.run_queue)
    |> assign(:io_in_kbs, new_metrics.io_in_kbs)
    |> assign(:io_out_kbs, new_metrics.io_out_kbs)
    |> assign(:labels, new_metrics.labels)
    |> assign(:mem_series, new_metrics.mem_series)
    |> assign(:runq_series, new_metrics.runq_series)
    |> assign(:ioin_series, new_metrics.ioin_series)
    |> assign(:ioout_series, new_metrics.ioout_series)
  end

  defp initial_metrics do
    %{
      last_io_in: 0,
      last_io_out: 0,
      labels: [],
      mem_series: [],
      runq_series: [],
      ioin_series: [],
      ioout_series: [],
      uptime_min: 0,
      memory_mb: 0,
      run_queue: 0,
      io_in_kbs: 0,
      io_out_kbs: 0
    }
  end

  defp collect_metrics(%{last_io_in: last_in, last_io_out: last_out} = m) do
    now_label = Time.utc_now() |> Time.truncate(:second) |> Time.to_string()

    total_mem_bytes = :erlang.memory(:total)
    memory_mb = Float.round(total_mem_bytes / 1_048_576, 1)

    run_queue = :erlang.statistics(:run_queue)

    {{:input, io_in}, {:output, io_out}} = :erlang.statistics(:io)
    delta_in = max(io_in - last_in, 0)
    delta_out = max(io_out - last_out, 0)
    # bytes over 30_000 milliseconds -> KB/s
    sec = 60_000 / 1000
    io_in_kbs = Float.round(delta_in / 1024 / sec, 1)
    io_out_kbs = Float.round(delta_out / 1024 / sec, 1)

    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    uptime_min = Integer.floor_div(uptime_ms, 60_000)

    m
    |> Map.put(:last_io_in, io_in)
    |> Map.put(:last_io_out, io_out)
    |> Map.put(:uptime_min, uptime_min)
    |> Map.put(:memory_mb, memory_mb)
    |> Map.put(:run_queue, run_queue)
    |> Map.put(:io_in_kbs, io_in_kbs)
    |> Map.put(:io_out_kbs, io_out_kbs)
    |> append_point(:labels, now_label)
    |> append_point(:mem_series, memory_mb)
    |> append_point(:runq_series, run_queue)
    |> append_point(:ioin_series, io_in_kbs)
    |> append_point(:ioout_series, io_out_kbs)
  end

  defp append_point(m, key, value) do
    series = Map.get(m, key, [])
    series = (series ++ [value]) |> trim_left(@max_points)
    Map.put(m, key, series)
  end

  defp trim_left(list, max) when length(list) <= max, do: list
  defp trim_left(list, max), do: Enum.take(list, -max)

  defp assign_initial_system_metrics(socket) do
    # Get initial system metrics immediately
    total_mem_bytes = :erlang.memory(:total)
    memory_mb = Float.round(total_mem_bytes / 1_048_576, 1)
    run_queue = :erlang.statistics(:run_queue)
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    uptime_min = Integer.floor_div(uptime_ms, 60_000)

    socket
    |> assign(:uptime_min, uptime_min)
    |> assign(:memory_mb, memory_mb)
    |> assign(:run_queue, run_queue)
    |> assign(:io_in_kbs, 0)
    |> assign(:io_out_kbs, 0)
    |> assign(:labels, [])
    |> assign(:mem_series, [])
    |> assign(:runq_series, [])
    |> assign(:ioin_series, [])
    |> assign(:ioout_series, [])
  end

  # ===== Statistical aggregates for charts =====
  defp assign_stats(socket) do
    {prog_labels, prog_counts} = students_by_program()
    {users_labels, users_counts} = new_users_last_7_days()
    {otps_active, otps_inactive} = otp_status_counts()
    {qr_active, qr_expired} = qr_status_counts()

    # Add attendance chart data (admin view - all courses)
    {daily_labels, daily_qr_data, daily_otp_data} = admin_daily_attendance()
    {weekly_trend_labels, weekly_trend_data} = admin_weekly_trend()
    {signin_qr, signin_otp} = admin_signin_distribution()

    # Get course attendance stats
    {course_labels, course_counts} = admin_course_attendance_stats()

    # Get attendance summary
    attendance_summary = admin_attendance_summary()

    socket
    |> assign(:prog_labels, prog_labels)
    |> assign(:prog_counts, prog_counts)
    |> assign(:users_labels, users_labels)
    |> assign(:users_counts, users_counts)
    |> assign(:otps_active, otps_active)
    |> assign(:otps_inactive, otps_inactive)
    |> assign(:qr_active, qr_active)
    |> assign(:qr_expired, qr_expired)
    |> assign(:daily_labels, daily_labels)
    |> assign(:daily_qr_data, daily_qr_data)
    |> assign(:daily_otp_data, daily_otp_data)
    |> assign(:weekly_trend_labels, weekly_trend_labels)
    |> assign(:weekly_trend_data, weekly_trend_data)
    |> assign(:signin_qr, signin_qr)
    |> assign(:signin_otp, signin_otp)
    |> assign(:course_labels, course_labels)
    |> assign(:course_counts, course_counts)
    |> assign(:attendance_labels, users_labels)
    |> assign(:attendance_counts, users_counts)
    |> assign(:attendance_summary, attendance_summary)
  end

  defp students_by_program do
    q = from s in Register.Students.Student,
      group_by: s.program,
      select: {s.program, count(s.id)}

    results = Repo.all(q)
    labels = Enum.map(results, fn {prog, _} -> prog || "Unknown" end)
    counts = Enum.map(results, fn {_, c} -> c end)
    {labels, counts}
  end

  defp new_users_last_7_days do
    q = from u in User,
      where: u.inserted_at >= from_now(-7, "day"),
      group_by: fragment("date_trunc('day', ?)", u.inserted_at),
      select: {fragment("date_trunc('day', ?)", u.inserted_at), count(u.id)}

    results = Repo.all(q)
    days = for i <- 6..0//-1, do: Date.utc_today() |> Date.add(-i)

    map =
      Enum.reduce(results, %{}, fn {dt, c}, acc ->
        date =
          case dt do
            %NaiveDateTime{} = ndt -> NaiveDateTime.to_date(ndt)
            %DateTime{} = dt -> DateTime.to_date(dt)
            _ -> Date.utc_today()
          end
        Map.update(acc, date, c, &(&1 + c))
      end)

    labels = Enum.map(days, &Date.to_iso8601/1)
    counts = Enum.map(days, fn d -> Map.get(map, d, 0) end)
    {labels, counts}
  end

  defp otp_status_counts do
    q_active = from o in Register.Otps.Otp, where: o.is_active == true, select: count(o.id)
    q_inactive = from o in Register.Otps.Otp, where: o.is_active == false, select: count(o.id)
    {Repo.one(q_active) || 0, Repo.one(q_inactive) || 0}
  end

  defp qr_status_counts do
    now = DateTime.utc_now()
    q_active = from("qr_codes", as: :q,
      where: field(as(:q), :is_active) == true,
      where: is_nil(field(as(:q), :expires_at)) or field(as(:q), :expires_at) > ^now,
      select: count(field(as(:q), :id)))

    q_expired = from("qr_codes", as: :q,
      where: not is_nil(field(as(:q), :expires_at)) and field(as(:q), :expires_at) <= ^now,
      select: count(field(as(:q), :id)))

    {Repo.one(q_active) || 0, Repo.one(q_expired) || 0}
  end

  defp count_courses do
    from(c in "courses", where: c.is_active == true, select: count(c.id))
    |> Repo.one() || 0
  end

  defp count_programs do
    from(p in "programs", where: p.is_active == true, select: count(p.id))
    |> Repo.one() || 0
  end

  defp count_qr_codes do
    from(q in "qr_codes", select: count(q.id))
    |> Repo.one() || 0
  end

  defp count_otps do
    from(o in "otp", select: count(o.id))
    |> Repo.one() || 0
  end

  defp count_today_attendance do
    today = Date.utc_today()
    from(a in "attendance_records", where: a.session_date == ^today, select: count(a.id))
    |> Repo.one() || 0
  end

  defp get_students_per_course do
    from(a in "attendance_records",
      join: c in "courses", on: a.course_id == c.id,
      group_by: c.id,
      select: {c.title, count(a.student_id)})
    |> Repo.all()
  end

  defp get_recent_activities do
    # Get recent attendance records
    attendance_query = from(a in "attendance_records",
      join: u in "users", on: a.student_id == u.id,
      order_by: [desc: a.inserted_at],
      limit: 5,
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
      order_by: [desc: q.inserted_at],
      limit: 3,
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
      order_by: [desc: o.inserted_at],
      limit: 3,
      select: %{
        type: "otp",
        user_name: fragment("? || ' ' || ?", u.first_name, u.last_name),
        user_email: u.email,
        action: "generated OTP",
        target: o.course_name,
        timestamp: o.inserted_at,
        details: o.session_date
      })

    # Combine and sort all activities
    activities =
      (Repo.all(attendance_query) ++ Repo.all(qr_query) ++ Repo.all(otp_query))
      |> Enum.sort_by(fn activity ->
        case activity.timestamp do
          %DateTime{} -> activity.timestamp
          %NaiveDateTime{} -> DateTime.from_naive!(activity.timestamp, "Etc/UTC")
          _ -> DateTime.utc_now()
        end
      end, {:desc, DateTime})
      |> Enum.take(10)

    activities
  end

  # ===== Admin Attendance Chart Functions =====

  defp admin_daily_attendance do
    # Get attendance by module/session for today (all courses)
    today = Date.utc_today()

    # Query attendance records for today, grouped by session and method
    query = from ar in "attendance_records",
      where: ar.session_date == ^today,
      group_by: [ar.method, ar.module_code],
      select: {
        ar.method,
        ar.module_code,
        count(ar.id)
      },
      order_by: ar.module_code,
      limit: 24  # Limit to prevent too much data

    results = Repo.all(query)

    # Get unique module codes for today's sessions
    module_codes = results
      |> Enum.map(fn {_, module_code, _} -> module_code end)
      |> Enum.uniq()
      |> Enum.take(6) # Limit to 6 sessions for chart readability

    labels = if length(module_codes) > 0 do
      module_codes
    else
      ["No Sessions Today"]
    end

    # Process results into QR and OTP data by module
    {qr_data, otp_data} = Enum.reduce(module_codes, {[], []}, fn module_code, {qr_acc, otp_acc} ->
      qr_count = Enum.find(results, fn {method, mod, _} -> method == "qr" and mod == module_code end)
      otp_count = Enum.find(results, fn {method, mod, _} -> method == "otp" and mod == module_code end)

      qr_val = if qr_count, do: elem(qr_count, 2), else: 0
      otp_val = if otp_count, do: elem(otp_count, 2), else: 0

      {[qr_val | qr_acc], [otp_val | otp_acc]}
    end)

    # Reverse to maintain order
    qr_data = Enum.reverse(qr_data)
    otp_data = Enum.reverse(otp_data)

    {labels, qr_data, otp_data}
  end

  defp admin_weekly_trend do
    # Get attendance for last 7 days grouped by day
    start_date = Date.add(Date.utc_today(), -6)

    query = from ar in "attendance_records",
      where: ar.session_date >= ^start_date,
      group_by: ar.session_date,
      select: {ar.session_date, count(ar.id)},
      order_by: ar.session_date

    results = Repo.all(query)
    attendance_map = Map.new(results)

    # Generate labels and data for the last 7 days
    dates = for i <- 0..6, do: Date.add(start_date, i)

    labels = Enum.map(dates, fn date ->
      case Date.day_of_week(date) do
        1 -> "Mon"
        2 -> "Tue"
        3 -> "Wed"
        4 -> "Thu"
        5 -> "Fri"
        6 -> "Sat"
        7 -> "Sun"
      end
    end)

    data = Enum.map(dates, fn date -> Map.get(attendance_map, date, 0) end)

    {labels, data}
  end

  defp admin_signin_distribution do
    # Get total attendance by method for all time
    qr_query = from ar in "attendance_records",
      where: ar.method == "qr",
      select: count(ar.id)

    otp_query = from ar in "attendance_records",
      where: ar.method == "otp",
      select: count(ar.id)

    qr_count = Repo.one(qr_query) || 0
    otp_count = Repo.one(otp_query) || 0

    {qr_count, otp_count}
  end

  defp admin_course_attendance_stats do
    # Get attendance counts per course
    query = from ar in "attendance_records",
      join: c in "courses", on: ar.course_id == c.id,
      group_by: c.id,
      select: {c.title, count(ar.id)},
      order_by: [desc: count(ar.id)],
      limit: 10

    results = Repo.all(query)

    labels = Enum.map(results, fn {title, _} -> title end)
    counts = Enum.map(results, fn {_, count} -> count end)

    {labels, counts}
  end

  defp admin_attendance_summary do
    # Get overall attendance summary
    total_attendance_query = from ar in "attendance_records", select: count(ar.id)
    total_attendance = Repo.one(total_attendance_query) || 0

    unique_students_query = from ar in "attendance_records", select: count(ar.student_id, :distinct)
    unique_students = Repo.one(unique_students_query) || 0

    # Get recent sessions
    recent_sessions_query = from ar in "attendance_records",
      join: u in "users", on: ar.student_id == u.id,
      join: c in "courses", on: ar.course_id == c.id,
      order_by: [desc: ar.inserted_at],
      limit: 10,
      select: %{
        student_name: fragment("? || ' ' || ?", u.first_name, u.last_name),
        course: %{title: c.title},
        module_code: ar.module_code,
        type: ar.method,
        inserted_at: ar.inserted_at
      }

    sessions = Repo.all(recent_sessions_query)

    %{
      total_attendance: total_attendance,
      unique_students: unique_students,
      sessions: sessions
    }
  end
end
