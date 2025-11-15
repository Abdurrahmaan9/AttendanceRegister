defmodule RegisterWeb.Lecturer.OTPLive.Index do
  use RegisterWeb, :live_view
  alias Register.Otps
  alias Register.Courses
  alias RegisterWeb.Plugs.MfaAuth
  alias RegisterWeb.Admin.OTPManagementLive.Helpers, as: OTPHelpers

  @impl true
  def mount(_params, _session, socket) do
    lecturer_id = socket.assigns.current_user.id
    courses = list_lecturer_courses(lecturer_id)
    otps = Otps.list_otps_for_user(lecturer_id)

    form =
      to_form(%{
        "course_id" => "",
        "location" => "",
        "expires_in" => "5"
      })

    {:ok,
     socket
     |> assign(:courses, courses)
     |> assign(:otp, nil)
     |> assign(:selected_otp, nil)
     |> assign(:otps, otps)
     |> assign(:sidebar_open, false)
     |> assign(:form, form)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Generate OTP for Attendance")
  end

  @impl true
  def handle_event("generate", %{"form" => params}, socket) do
    course_id = String.to_integer(params["course_id"])
    expires_in = String.to_integer(params["expires_in"] || "5")

    case Enum.find(socket.assigns.courses, &(&1.id == course_id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Invalid course selected")}

      course ->
        case MfaAuth.generate_attendance_pass(
               socket.assigns.current_user,
               course,
               location: params["location"],
               expires_in_minutes: expires_in
             ) do
          {:ok, otp} ->
            otps = Otps.list_otps_for_user(socket.assigns.current_user.id)

            {:noreply,
             socket
             |> assign(:otp, otp)
             |> assign(:selected_otp, otp)
             |> assign(:otps, otps)
             |> put_flash(:info, "OTP generated successfully!")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to generate OTP")}
        end
    end
  end

  @impl true
  def handle_event("view_otp", %{"id" => id}, socket) do
    with {otp_id, ""} <- Integer.parse(id),
         %{id: user_id} <- socket.assigns.current_user,
         otp when not is_nil(otp) <- Otps.get_otp_for_user(otp_id, user_id) do
      {:noreply, assign(socket, :selected_otp, otp)}
    else
      _ ->
        {:noreply, put_flash(socket, :error, "OTP not found")}
    end
  end

  @impl true
  def handle_event("delete_otp", %{"id" => id}, socket) do
    with {otp_id, ""} <- Integer.parse(id),
         %{id: user_id} <- socket.assigns.current_user,
         {:ok, _} <- Otps.delete_otp_for_user(otp_id, user_id) do
      otps = Otps.list_otps_for_user(user_id)

      selected_otp =
        case socket.assigns[:selected_otp] do
          %{id: ^otp_id} -> nil
          other -> other
        end

      {:noreply,
       socket
       |> assign(:otps, otps)
       |> assign(:selected_otp, selected_otp)
       |> put_flash(:info, "OTP deleted successfully")}
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Unable to delete OTP")}
    end
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  defp list_lecturer_courses(user_id) do
    Register.Academic.list_lecturer_courses(user_id)
  end
end
