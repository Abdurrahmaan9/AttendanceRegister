defmodule Register.AttendanceUpdater do
  use GenServer
  require Logger
  import Ecto.Query

  @update_interval :timer.minutes(5) # Update every 5 minutes

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    Logger.info("AttendanceUpdater started - will update every #{div(@update_interval, 60_000)} minutes")

    # Schedule periodic work
    schedule_work()

    {:ok, %{}}
  end

  @impl true
  def handle_info(:update_attendance_data, state) do
    Logger.info("Updating attendance data...")

    # Update attendance data for all lecturers
    update_all_lecturer_attendance()

    # Schedule next update
    schedule_work()

    {:noreply, state}
  end

  # Private functions
  defp schedule_work do
    Process.send_after(self(), :update_attendance_data, @update_interval)
  end

  defp update_all_lecturer_attendance do
    # Get all active lecturers
    lecturers = Register.Repo.all(
      from u in Register.Accounts.User,
        where: u.role == "lecturer" and u.is_active == true
    )

    # Update attendance data for each lecturer
    Enum.each(lecturers, fn lecturer ->
      update_lecturer_attendance(lecturer.id)
    end)
  end

  defp update_lecturer_attendance(lecturer_id) do
    try do
      # Get attendance data for this lecturer
      {daily_labels, daily_qr_data, daily_otp_data} = lecturer_daily_attendance(lecturer_id)
      {weekly_trend_labels, weekly_trend_data} = lecturer_weekly_trend(lecturer_id)
      {signin_qr, signin_otp} = lecturer_signin_distribution(lecturer_id)

      # Broadcast updated data to LiveView
      RegisterWeb.Endpoint.broadcast!(
        "lecturer_dashboard:#{lecturer_id}",
        "attendance_update",
        %{
          daily_labels: daily_labels,
          daily_qr_data: daily_qr_data,
          daily_otp_data: daily_otp_data,
          weekly_trend_labels: weekly_trend_labels,
          weekly_trend_data: weekly_trend_data,
          signin_qr: signin_qr,
          signin_otp: signin_otp
        }
      )

      Logger.debug("Updated attendance data for lecturer #{lecturer_id}")
    rescue
      e ->
        Logger.error("Failed to update attendance for lecturer #{lecturer_id}: #{inspect(e)}")
    end
  end

  # Data aggregation functions (moved from LiveView)
  defp lecturer_daily_attendance(lecturer_id) do
    today = Date.utc_today()

    # Query attendance records for today, grouped by session and method
    query = from ar in "attendance_records",
      join: o in "otp", on: o.course_id == ar.course_id and o.module_code == ar.module_code,
      where: o.created_by_id == ^lecturer_id and ar.session_date == ^today,
      group_by: [ar.method, ar.module_code],
      select: {
        ar.method,
        ar.module_code,
        count(ar.id)
      },
      order_by: ar.module_code

    results = Register.Repo.all(query)

    # Group by session/module instead of hours for course attendance overview
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

  defp lecturer_weekly_trend(lecturer_id) do
    start_date = Date.add(Date.utc_today(), -6)

    query = from ar in "attendance_records",
      join: o in "otp", on: o.course_id == ar.course_id and o.module_code == ar.module_code,
      where: o.created_by_id == ^lecturer_id and ar.session_date >= ^start_date,
      group_by: ar.session_date,
      select: {ar.session_date, count(ar.id)},
      order_by: ar.session_date

    results = Register.Repo.all(query)
    attendance_map = Map.new(results)

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

  defp lecturer_signin_distribution(lecturer_id) do
    qr_query = from ar in "attendance_records",
      join: o in "otp", on: o.course_id == ar.course_id and o.module_code == ar.module_code,
      where: o.created_by_id == ^lecturer_id and ar.method == "qr",
      select: count(ar.id)

    otp_query = from ar in "attendance_records",
      join: o in "otp", on: o.course_id == ar.course_id and o.module_code == ar.module_code,
      where: o.created_by_id == ^lecturer_id and ar.method == "otp",
      select: count(ar.id)

    qr_count = Register.Repo.one(qr_query) || 0
    otp_count = Register.Repo.one(otp_query) || 0

    {qr_count, otp_count}
  end
end
