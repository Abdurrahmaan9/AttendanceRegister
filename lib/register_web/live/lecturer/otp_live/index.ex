defmodule RegisterWeb.Lecturer.OTPLive.Index do
  use RegisterWeb, :live_view
  alias Register.Otps
  alias Register.Courses
  alias RegisterWeb.Plugs.MfaAuth

  @impl true
  def mount(_params, _session, socket) do
    courses = list_lecturer_courses(socket.assigns.current_user.id)

    {:ok,
      socket
      |> assign(:courses, courses)
      |> assign(:otp, nil)
      |> assign(:form, to_form(%{
        "course_id" => "",
        "location" => "",
        "expires_in" => "30"
      }))
    }
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
    expires_in = String.to_integer(params["expires_in"] || "30")

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
            {:noreply,
              socket
              |> assign(:otp, otp)
              |> put_flash(:info, "OTP generated successfully!")
            }

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to generate OTP")}
        end
    end
  end

  defp list_lecturer_courses(lecturer_id) do
    # TODO: Update this to filter courses by the current lecturer
    Courses.list_courses()
  end
end
