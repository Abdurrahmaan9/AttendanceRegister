defmodule RegisterWeb.Students.Dashboard.Index do
  use RegisterWeb, :live_view
  alias Register.Students
  alias Register.Attendance
  alias Register.Academic
  alias Register.Repo
  import Ecto.Query

  @url "/Students/dashboard"
  @sample_interval 5_000
  @max_points 20

  @impl true
  def mount(_params, session, socket) do
    current_user = get_session_user(session)

    # Get student's courses and enrollment
    courses = if current_user, do: list_student_courses(current_user.id), else: []

    total_courses = length(courses)
    total_attendance = count_student_attendance(current_user.id)
    today_attendance = count_today_student_attendance(current_user.id)
    upcoming_sessions = count_upcoming_sessions(current_user.id)

    socket =
      socket
      |> assign(:current_path, @url)
      |> assign(:sidebar_open, false)
      |> assign(:current_user, current_user)
      |> assign(:loading, true)
      |> assign(:courses, courses)
      |> assign(:total_courses, total_courses)
      |> assign(:total_attendance, total_attendance)
      |> assign(:today_attendance, today_attendance)
      |> assign(:upcoming_sessions, upcoming_sessions)
      |> assign_new(:metrics, fn -> initial_metrics() end)
      |> assign_student_stats()

    if connected?(socket) and current_user do
      :timer.send_interval(@sample_interval, :sample_metrics)
      Process.send_after(self(), :load_student_data, 100)
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

  @impl true
  def handle_info(:load_student_data, socket) do
    # Load student data asynchronously
    socket = socket
      |> assign_student_stats()
      |> assign(:loading, false)

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

  defp assign_student_stats(socket) do
    current_user = socket.assigns.current_user

    if current_user do
      {attendance_labels, attendance_counts} = student_attendance_trend(current_user.id)
      {course_labels, course_counts} = student_courses_stats(current_user.id)
      recent_activities = get_student_recent_activities(current_user.id)

      socket
      |> assign(:attendance_labels, attendance_labels)
      |> assign(:attendance_counts, attendance_counts)
      |> assign(:course_labels, course_labels)
      |> assign(:course_counts, course_counts)
      |> assign(:recent_activities, recent_activities)
    else
      socket
    end
  end

  defp list_student_courses(student_id) do
    from(ar in "attendance_records",
      where: ar.student_id == ^student_id,
      distinct: ar.course_id,
      join: c in "courses", on: c.id == ar.course_id,
      select: %{
        id: c.id,
        title: c.title,
        code: c.code,
        credits: c.credits,
        description: c.description,
        is_active: c.is_active
      })
    |> Repo.all()
  end

  defp count_student_attendance(student_id) do
    from(a in "attendance_records",
      where: a.student_id == ^student_id,
      select: count(a.id))
    |> Repo.one() || 0
  end

  defp count_today_student_attendance(student_id) do
    today = Date.utc_today()
    from(a in "attendance_records",
      where: a.student_id == ^student_id and a.session_date == ^today,
      select: count(a.id))
    |> Repo.one() || 0
  end

  defp count_upcoming_sessions(student_id) do
    tomorrow = Date.utc_today() |> Date.add(1)
    from(a in "attendance_records",
      where: a.student_id == ^student_id and a.session_date >= ^tomorrow,
      select: count(a.id))
    |> Repo.one() || 0
  end

  defp student_attendance_trend(student_id) do
    start_date = Date.add(Date.utc_today(), -6)

    query = from ar in "attendance_records",
      where: ar.student_id == ^student_id and ar.session_date >= ^start_date,
      group_by: ar.session_date,
      select: {ar.session_date, count(ar.id)},
      order_by: ar.session_date

    results = Repo.all(query)

    dates = for i <- 0..6, do: Date.add(Date.utc_today(), -i)

    attendance_map = Map.new(results)

    labels = Enum.map(dates, &Date.to_iso8601/1)
    counts = Enum.map(dates, fn date -> Map.get(attendance_map, date, 0) end)

    {labels, counts}
  end

  defp student_courses_stats(student_id) do
    from(ar in "attendance_records",
      where: ar.student_id == ^student_id,
      join: c in "courses", on: c.id == ar.course_id,
      group_by: c.id,
      select: {c.title, count(ar.id)})
    |> Repo.all()
    |> then(fn results ->
      labels = Enum.map(results, fn {title, _} -> title end)
      counts = Enum.map(results, fn {_, count} -> count end)
      {labels, counts}
    end)
  end

  defp get_student_recent_activities(student_id) do
    from(a in "attendance_records",
      where: a.student_id == ^student_id,
      join: c in "courses", on: a.course_id == c.id,
      order_by: [desc: a.inserted_at],
      limit: 10,
      select: %{
        type: "attendance",
        course_name: c.title,
        module_code: a.module_code,
        method: a.method,
        timestamp: a.inserted_at,
        session_date: a.session_date
      })
    |> Repo.all()
  end
end
