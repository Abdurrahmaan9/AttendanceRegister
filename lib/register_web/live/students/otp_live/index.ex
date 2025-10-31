defmodule RegisterWeb.Students.OtpLive.Index do
  use RegisterWeb, :live_view
  require Logger
  alias RegisterWeb.Plugs.MfaAuth
  alias Register.Attendance
  alias Register.Accounts

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"module_code" => "", "otp" => ""}, as: :form)
    # Refresh the current_user from DB so first_name/last_name are present
    user = Accounts.get_user!(socket.assigns.current_user.id)

    {:ok,
      socket
      |> assign(:sidebar_open, false)
      |> assign(:current_user, user)
      |> assign(:form, form)
      |> assign(:attendance_recorded, false)
      |> assign(:course_info, nil)
      |> assign(:error, nil)
    }
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("verify_otp", %{"form" => %{"module_code" => module_code, "otp" => otp}}, socket) do
    case MfaAuth.valid_attendance_code?(module_code, otp) do
      {:ok, course_info} ->
        # Record attendance
        case Attendance.record_attendance(
          socket.assigns.current_user.id,
          course_info.course_id,
          course_info.module_code,
          course_info.course_name,
          course_info.session_date,
          %{
            method: "otp",
            first_name: socket.assigns.current_user.first_name,
            last_name: socket.assigns.current_user.last_name
          }
        ) do
          {:ok, _attendance} ->
            {:noreply,
              socket
              |> assign(:attendance_recorded, true)
              |> assign(:course_info, course_info)
              |> assign(:error, nil)
            }

          {:error, :already_marked} ->
            {:noreply,
              socket
              |> assign(:attendance_recorded, false)
              |> assign(:course_info, course_info)
              |> assign(:error, "You have already marked attendance for this session.")
            }

          {:error, _changeset} ->
            {:noreply,
              socket
              |> assign(:error, "Failed to record attendance. Please try again.")
            }
        end

      {:error, :not_found} ->
        {:noreply,
          socket
          |> assign(:error, "Invalid or expired OTP. Please check and try again.")
        }

      {:error, :expired} ->
        {:noreply,
          socket
          |> assign(:error, "This OTP has expired. Please ask your lecturer for a new one.")
        }
    end
  end

  @impl true
  def handle_event("verify_otp", %{"module_code" => module_code, "otp" => otp}, socket) do
    case MfaAuth.valid_attendance_code?(module_code, otp) do
      {:ok, course_info} ->
        # Record attendance
        case Attendance.record_attendance(
          socket.assigns.current_user.id,
          course_info.course_id,
          course_info.module_code,
          course_info.course_name,
          course_info.session_date,
          %{
            method: "otp",
            first_name: socket.assigns.current_user.first_name,
            last_name: socket.assigns.current_user.last_name
          }
        ) do
          {:ok, _attendance} ->
            {:noreply,
              socket
              |> assign(:attendance_recorded, true)
              |> assign(:course_info, course_info)
              |> assign(:error, nil)
            }

          {:error, :already_marked} ->
            {:noreply,
              socket
              |> assign(:attendance_recorded, false)
              |> assign(:course_info, course_info)
              |> assign(:error, "You have already marked attendance for this session.")
            }

          {:error, _changeset} ->
            {:noreply,
              socket
              |> assign(:error, "Failed to record attendance. Please try again.")
            }
        end

      {:error, :not_found} ->
        {:noreply,
          socket
          |> assign(:error, "Invalid or expired OTP. Please check and try again.")
        }

      {:error, :expired} ->
        {:noreply,
          socket
          |> assign(:error, "This OTP has expired. Please ask your lecturer for a new one.")
        }
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Mark Attendance with OTP")
  end

  defp apply_action(socket, :show, %{"id" => _id}) do
    socket
    |> assign(:page_title, "View OTP")
  end

  defp apply_action(socket, :verify, %{"id" => _id}) do
    socket
    |> assign(:page_title, "Verify OTP")
  end
end
