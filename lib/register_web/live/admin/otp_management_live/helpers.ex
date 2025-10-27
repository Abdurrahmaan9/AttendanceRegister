defmodule RegisterWeb.Admin.OTPManagementLive.Helpers do
  @moduledoc """
  Helper functions for OTP Management LiveView components.
  """
  

  @doc """
  Renders a status badge for the OTP based on its active status and expiration.
  Returns raw HTML that can be used with raw/1 in templates.
  """
  def otp_status(%{is_active: true, expires_at: expires_at}) when not is_nil(expires_at) do
    now = DateTime.utc_now()
    
    if DateTime.compare(now, expires_at) == :lt do
      ~s(<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">Active</span>)
    else
      ~s(<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">Expired</span>)
    end
  end

  def otp_status(%{is_active: false}) do
    ~s(<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">Inactive</span>)
  end

  def otp_status(_), do: ""

  @doc """
  Formats the expiration time in a human-readable format.
  """
  def format_expiration(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_naive()
    |> format_expiration()
  end

  def format_expiration(%NaiveDateTime{} = datetime) do
    datetime
    |> NaiveDateTime.to_string()
    |> format_expiration()
  end

  def format_expiration(datetime_str) when is_binary(datetime_str) do
    cond do
      # Try parsing as ISO8601 DateTime
      match?({:ok, _, _}, DateTime.from_iso8601(datetime_str)) ->
        {:ok, datetime, _} = DateTime.from_iso8601(datetime_str)
        format_expiration(datetime)
        
      # Try parsing as ISO8601 NaiveDateTime
      match?({:ok, _}, NaiveDateTime.from_iso8601(datetime_str)) ->
        {:ok, ndt} = NaiveDateTime.from_iso8601(datetime_str)
        format_expiration(ndt)
        
      # Try parsing as space-separated date and time
      String.contains?(datetime_str, " ") ->
        case String.split(datetime_str, " ", trim: true) do
          [date, time] ->
            with [year, month_str, day_str] when byte_size(month_str) in [1, 2] <- String.split(date, "-"),
                 [hour, minute, _] <- String.split(time, ":"),
                 {month, ""} <- Integer.parse(month_str),
                 {day, ""} <- Integer.parse(day_str) do
              month_name = month_name(month)
              {hour_fmt, ampm} = format_hour_ampm(hour)
              "#{month_name} #{day}, #{year} at #{hour_fmt}:#{minute} #{ampm}"
            else
              _ -> datetime_str
            end
          _ ->
            datetime_str
        end
        
      # Fallback to original string
      true ->
        datetime_str
    end
  end
  
  def format_expiration(_), do: "N/A"
  
  defp month_name(1), do: "Jan"
  defp month_name(2), do: "Feb"
  defp month_name(3), do: "Mar"
  defp month_name(4), do: "Apr"
  defp month_name(5), do: "May"
  defp month_name(6), do: "Jun"
  defp month_name(7), do: "Jul"
  defp month_name(8), do: "Aug"
  defp month_name(9), do: "Sep"
  defp month_name(10), do: "Oct"
  defp month_name(11), do: "Nov"
  defp month_name(12), do: "Dec"
  
  defp format_hour_ampm(hour_str) when is_binary(hour_str) do
    hour = String.to_integer(hour_str)
    format_hour_ampm(hour)
  end
  
  defp format_hour_ampm(hour) when hour == 0, do: {"12", "AM"}
  defp format_hour_ampm(hour) when hour < 12, do: {"#{hour}", "AM"}
  defp format_hour_ampm(hour) when hour == 12, do: {"12", "PM"}
  defp format_hour_ampm(hour), do: {"#{hour - 12}", "PM"}

  @doc """
  Calculates the time remaining until expiration.
  """
  def time_remaining(%DateTime{} = expires_at) do
    now = DateTime.utc_now()
    
    if DateTime.compare(now, expires_at) == :lt do
      diff = DateTime.diff(expires_at, now, :second)
      
      cond do
        diff < 60 -> "Expires in #{diff} seconds"
        diff < 3600 -> "Expires in #{div(diff, 60)} minutes"
        diff < 86400 -> "Expires in #{div(diff, 3600)} hours"
        true -> "Expires in #{div(diff, 86400)} days"
      end
    else
      "Expired"
    end
  end

  def time_remaining(_), do: "No expiration"

  @doc """
  Truncates a string to a specified length, with an ellipsis if truncated.
  """
  def truncate(text, length \\ 50) do
    if String.length(text) > length do
      String.slice(text, 0, length) <> "..."
    else
      text
    end
  end
end
