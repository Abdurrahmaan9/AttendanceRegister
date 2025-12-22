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
  def mount(_params, _session, socket) do
    total_students = Students.count_students()
    total_staff = Accounts.total_users_by_roles(["lecturer", "admin", "staff"])
    total_sessions_for_day = Attendance.total_classes_for_day()
    total_courses = count_courses()
    total_programs = count_programs()
    total_qr_codes = count_qr_codes()
    total_otps = count_otps()
    today_attendance = count_today_attendance()
    students_per_course = get_students_per_course()
    recent_activities = get_recent_activities()

    socket =
      socket
      |> assign(:current_path, @url)
      |> assign(:sidebar_open, false)
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
      |> assign_new(:metrics, fn -> initial_metrics() end)
      |> assign_stats()

    if connected?(socket) do
      :timer.send_interval(@sample_interval, :sample_metrics)
    end

    {:ok, sample_and_assign(socket)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_info(:sample_metrics, socket) do
    {:noreply, sample_and_assign(socket)}
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
    # bytes over @sample_interval seconds -> KB/s
    sec = @sample_interval / 1000
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

  # ===== Statistical aggregates for charts =====
  defp assign_stats(socket) do
    {prog_labels, prog_counts} = students_by_program()
    {users_labels, users_counts} = new_users_last_7_days()
    {otps_active, otps_inactive} = otp_status_counts()
    {qr_active, qr_expired} = qr_status_counts()

    socket
    |> assign(:prog_labels, prog_labels)
    |> assign(:prog_counts, prog_counts)
    |> assign(:users_labels, users_labels)
    |> assign(:users_counts, users_counts)
    |> assign(:otps_active, otps_active)
    |> assign(:otps_inactive, otps_inactive)
    |> assign(:qr_active, qr_active)
    |> assign(:qr_expired, qr_expired)
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
end
