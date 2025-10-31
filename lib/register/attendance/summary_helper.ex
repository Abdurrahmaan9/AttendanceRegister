defmodule Register.Attendance.SummaryHelper do
  @moduledoc false

  @doc """
  Compute attendance rate (0.0-100.0) from attended and total session counts.
  """
  def rate(attended, total) when is_integer(attended) and is_integer(total) and total > 0 do
    attended
    |> Kernel./(total)
    |> Kernel.*(100.0)
    |> Float.round(1)
  end

  def rate(_attended, _total), do: 0.0
end
