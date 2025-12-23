defmodule RegisterWeb.Lecturer.Dashboard.Index do
  use RegisterWeb, :live_view
  alias Register.Students
  alias Register.Accounts
  alias Register.Attendance
  alias Register.Academic
  alias Register.Repo
  import Ecto.Query

  @url "/Lecturer/dashboard"

  @impl true
  def mount(_params, session, socket) do
    current_user = get_session_user(session)

    # Get lecturer's courses
    courses = if current_user, do: Academic.list_lecturer_courses(current_user.id), else: []

    # Basic stats
    total_students = Students.count_students()

    socket =
      socket
      |> assign(:current_path, @url)
      |> assign(:sidebar_open, false)
      |> assign(:current_user, current_user)
      |> assign(:total_students, total_students)
      |> assign(:courses, courses)
      |> assign_new(:metrics, fn -> initial_metrics() end)
      |> assign_lecturer_stats()
      |> assign_initial_system_metrics()

    if connected?(socket) and current_user do
      :timer.send_interval(5_000, :sample_metrics)
      {:ok, sample_and_assign(socket)}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_info(:sample_metrics, socket) do
    {:noreply, sample_and_assign(socket)}
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
    # bytes over 5_000 milliseconds -> KB/s
    sec = 5_000 / 1000
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
    series = (series ++ [value]) |> trim_left(20)
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

  # ===== Lecturer-specific statistics =====
  defp assign_lecturer_stats(socket) do
    current_user = socket.assigns.current_user

    if current_user do
      {course_labels, course_counts} = lecturer_courses_stats(current_user.id)
      {attendance_labels, attendance_counts} = lecturer_attendance_trend(current_user.id)
      {qr_active, qr_inactive} = lecturer_qr_status(current_user.id)
      {otp_active, otp_inactive} = lecturer_otp_status(current_user.id)

      # Get attendance summary
      attendance_summary = Attendance.lecturer_attendance_summary(%{
        lecturer_id: current_user.id,
        course_id: nil
      })

      socket
      |> assign(:course_labels, course_labels)
      |> assign(:course_counts, course_counts)
      |> assign(:attendance_labels, attendance_labels)
      |> assign(:attendance_counts, attendance_counts)
      |> assign(:qr_active, qr_active)
      |> assign(:qr_inactive, qr_inactive)
      |> assign(:otp_active, otp_active)
      |> assign(:otp_inactive, otp_inactive)
      |> assign(:attendance_summary, attendance_summary)
    else
      socket
    end
  end

  defp lecturer_courses_stats(lecturer_id) do
    courses = Academic.list_lecturer_courses(lecturer_id)

    # Get attendance counts per course
    course_stats =
      Enum.map(courses, fn course ->
        total_attendance =
          from(ar in "attendance_records",
            where: ar.course_id == ^course.id,
            select: count(ar.id)
          )
          |> Repo.one() || 0

        {course.title, total_attendance}
      end)

    labels = Enum.map(course_stats, fn {title, _} -> title end)
    counts = Enum.map(course_stats, fn {_, count} -> count end)

    {labels, counts}
  end

  defp lecturer_attendance_trend(lecturer_id) do
    # Get attendance for last 7 days
    start_date = Date.add(Date.utc_today(), -6)

    query = from ar in "attendance_records",
      join: o in "otp", on: o.course_id == ar.course_id and o.module_code == ar.module_code,
      where: o.created_by_id == ^lecturer_id and ar.session_date >= ^start_date,
      group_by: ar.session_date,
      select: {ar.session_date, count(ar.id)},
      order_by: ar.session_date

    results = Repo.all(query)

    # Fill in missing dates with 0
    dates = for i <- 0..6, do: Date.add(Date.utc_today(), -i)

    attendance_map = Map.new(results)

    labels = Enum.map(dates, &Date.to_iso8601/1)
    counts = Enum.map(dates, fn date -> Map.get(attendance_map, date, 0) end)

    {labels, counts}
  end

  defp lecturer_qr_status(lecturer_id) do
    now = DateTime.utc_now()

    active_query = from q in "qr_codes",
      where: q.created_by_id == ^lecturer_id,
      where: q.is_active == true,
      where: is_nil(q.expires_at) or q.expires_at > ^now,
      select: count(q.id)

    inactive_query = from q in "qr_codes",
      where: q.created_by_id == ^lecturer_id,
      where: q.is_active == false or (not is_nil(q.expires_at) and q.expires_at <= ^now),
      select: count(q.id)

    active = Repo.one(active_query) || 0
    inactive = Repo.one(inactive_query) || 0

    {active, inactive}
  end

  defp lecturer_otp_status(lecturer_id) do
    active_query = from o in "otp",
      where: o.created_by_id == ^lecturer_id,
      where: o.is_active == true,
      select: count(o.id)

    inactive_query = from o in "otp",
      where: o.created_by_id == ^lecturer_id,
      where: o.is_active == false,
      select: count(o.id)

    active = Repo.one(active_query) || 0
    inactive = Repo.one(inactive_query) || 0

    {active, inactive}
  end
end
