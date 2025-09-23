defmodule Register.Otps do
  @moduledoc """
  The Otps context.
  """

  import Ecto.Query, warn: false
  alias Register.Repo
  alias Register.Otps.Otp

  @doc """
  Returns the list of OTPs.
  """
  def list_otps do
    require Logger
    Logger.debug("Starting to list OTPs")
    
    deactivate_expired_otps()
    
    query = from o in Otp,
      preload: :created_by,
      order_by: [desc: o.inserted_at]
      
    otps = Repo.all(query)
    Logger.debug("Found #{length(otps)} OTPs in database")
    
    if Enum.any?(otps) do
      Logger.debug("First OTP: #{inspect(List.first(otps), limit: :infinity, pretty: true)}")
    end
    
    otps
  end

  @doc """
  Gets a single OTP.
  """
  def get_otp!(id), do: Repo.get!(Otp, id) |> Repo.preload(:created_by)

  @doc """
  Creates an OTP.
  """
  def create_otp(attrs \\ %{}) do
    %Otp{}
    |> Otp.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an OTP.
  """
  def update_otp(%Otp{} = otp, attrs) do
    otp
    |> Otp.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an OTP.
  """
  def delete_otp(%Otp{} = otp) do
    Repo.delete(otp)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking OTP changes.
  """
  def change_otp(%Otp{} = otp, attrs \\ %{}) do
    Otp.changeset(otp, attrs)
  end

  @doc """
  Generates a new OTP with default expiration of 30 minutes.
  """
  def generate_otp(attrs \\ %{}) do
    expires_at = DateTime.utc_now() |> DateTime.add(30 * 60, :second)
    
    %{
      code: Otp.generate_code(),
      is_active: true,
      expires_at: expires_at,
      purpose: attrs[:purpose] || "authentication",
      metadata: %{},
      created_by_id: attrs[:created_by_id],
      course_id: attrs[:course_id],
      course_name: attrs[:course_name],
      module_code: attrs[:module_code],
      lecturer_name: attrs[:lecturer_name],
      location: attrs[:location],
      session_date: attrs[:session_date] || Date.utc_today()
    }
  end

  @doc """
  Generates a new OTP specifically for attendance.
  
  ## Parameters
    * `lecturer` - The lecturer generating the OTP
    * `course` - The course for which the OTP is being generated
    * `opts` - Additional options like :location, :expires_in_minutes
  """
  def generate_attendance_otp(lecturer, course, opts \\ []) do
    expires_in = Keyword.get(opts, :expires_in_minutes, 30)
    
    # Get lecturer name, fallback to email if name fields are not available
    lecturer_name = cond do
      function_exported?(lecturer, :first_name, 0) && function_exported?(lecturer, :last_name, 0) ->
        "#{lecturer.first_name} #{lecturer.last_name}"
      function_exported?(lecturer, :name, 0) ->
        lecturer.name
      true ->
        lecturer.email
    end
    
    otp_attrs = %{
      purpose: "attendance",
      created_by_id: lecturer.id,
      course_id: course.id,
      course_name: course.title,
      module_code: course.code,
      lecturer_name: lecturer_name,
      location: Keyword.get(opts, :location, "TBA"),
      session_date: Date.utc_today(),
      expires_in_minutes: expires_in
    }
    
    otp_attrs = Map.merge(otp_attrs, Map.new(opts))
    
    case create_otp(otp_attrs) do
      {:ok, otp} -> 
        {:ok, otp}
      {:error, changeset} -> 
        {:error, changeset}
    end
  end
  
  @doc """
  Verifies an attendance OTP and returns the associated course details if valid.
  """
  def verify_attendance_otp(code) do
    case verify_otp(code, "attendance") do
      {:ok, otp} ->
        {:ok, %{
          course_id: otp.course_id,
          course_name: otp.course_name,
          module_code: otp.module_code,
          lecturer_name: otp.lecturer_name,
          location: otp.location,
          session_date: otp.session_date
        }}
      error ->
        error
    end
  end

  @doc """
  Verifies if an OTP is valid.
  """
  def verify_otp(code, purpose) when is_binary(code) do
    now = DateTime.utc_now()
    
    case Repo.get_by(Otp, code: code, purpose: purpose, is_active: true) do
      %Otp{expires_at: expires_at} = otp ->
        if DateTime.compare(now, expires_at) == :lt do
          {:ok, otp}
        else
          update_otp(otp, %{is_active: false})
          {:error, :expired}
        end
      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Deactivates expired OTPs.
  """
  def deactivate_expired_otps do
    now = DateTime.utc_now()
    
    from(o in Otp, 
      where: o.is_active == true and o.expires_at < ^now
    )
    |> Repo.update_all(set: [is_active: false])
  end
end
