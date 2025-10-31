defmodule Register.Attendance.SummaryCache do
  use GenServer
  import Ecto.Query, warn: false
  alias Register.Repo
  alias Register.Academic.StudentProgram
  alias Register.Attendance

  @refresh_ms 2 * 60 * 1000
  @table :attendance_summary_cache

  # Public API
  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def get(student_id) when is_integer(student_id) do
    case :ets.lookup(@table, student_id) do
      [{^student_id, summary}] -> {:ok, summary}
      [] -> :miss
    end
  end

  def put(student_id, summary) when is_integer(student_id) and is_map(summary) do
    true = :ets.insert(@table, {student_id, summary})
    :ok
  end

  def refresh_student(student_id) when is_integer(student_id) do
    summary = Attendance.compute_attendance_summary(student_id)
    put(student_id, summary)
    :ok
  end

  def refresh_all do
    student_ids =
      from(sp in StudentProgram,
        where: sp.is_active == true,
        select: sp.student_id,
        distinct: true
      )
      |> Repo.all()

    Enum.each(student_ids, fn id ->
      summary = Attendance.compute_attendance_summary(id)
      put(id, summary)
    end)

    :ok
  end

  # GenServer callbacks
  @impl true
  def init(:ok) do
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    schedule_refresh()
    # Warm up cache once at boot (non-blocking)
    Task.start(fn -> refresh_all() end)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:refresh, state) do
    refresh_all()
    schedule_refresh()
    {:noreply, state}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_ms)
  end
end
