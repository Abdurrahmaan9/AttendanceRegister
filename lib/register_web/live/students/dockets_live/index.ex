defmodule RegisterWeb.Students.DocketsLive.Index do
  use RegisterWeb, :live_view
  alias Register.Dockets
  alias Register.Academic

  @url "/Students/dockets"

  @impl true
  def mount(_params, session, socket) do
    current_user = get_session_user(session)

    socket =
      socket
      |> assign(:current_path, @url)
      |> assign(:current_user, current_user)
      |> assign(:sidebar_open, false)

    if current_user do
      program_name =
        case Dockets.get_student_info(current_user.id) do
          {:ok, _user, student_program} -> student_program.program.name
          {:error, :no_program} -> "No Program Assigned"
          {:error, :not_found} -> "Unknown Program"
        end

      {:ok,
       socket
       |> assign(:program_name, program_name)
       |> assign(:docket_types, [
         %{type: "cat1", display: "CAT 1 Docket", icon: "📋"},
         %{type: "cat2", display: "CAT 2 Docket", icon: "📋"},
         %{type: "exam", display: "Exam Docket", icon: "📝"}
       ])}
    else
      {:ok, push_navigate(socket, to: "/")}
    end
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("select_docket", %{"type" => docket_type}, socket) do
    {:noreply,
     push_navigate(socket, to: "/Students/dockets/#{docket_type}")}
  end

  defp get_session_user(session) do
    case session["user_token"] do
      nil -> nil
      token -> Register.Accounts.get_user_by_session_token(token)
    end
  end
end
