defmodule RegisterWeb.Admin.LecturerProgramsLive.Index do
  use RegisterWeb, :live_view

  alias Register.Academic
  alias Register.Accounts
  alias Register.Academic.LecturerProgram

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :lecturers, Academic.list_lecturers_with_programs())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Manage Lecturer Programs")
    |> assign(:lecturer_program, nil)
  end

  defp apply_action(socket, :edit, %{"id" => user_id}), do: apply_action(socket, :edit, %{"user_id" => user_id})
  defp apply_action(socket, :edit, %{"user_id" => user_id}) do
    case Academic.get_lecturer_with_programs(user_id) do
      nil ->
        socket
        |> put_flash(:error, "Lecturer not found")
        |> push_navigate(to: ~p"/Admin/lecturers")
      
      lecturer ->
        unassigned_programs = Academic.list_unassigned_programs(user_id)
        socket
        |> assign(:page_title, "Edit Lecturer Programs")
        |> assign(:lecturer, lecturer)
        |> assign(:unassigned_programs, unassigned_programs)
    end
  end

  @impl true
  def handle_event("assign_program", %{"user_id" => user_id, "program_id" => program_id}, socket) do
    case Academic.assign_lecturer_to_program(user_id, program_id) do
      {:ok, _lecturer_program} ->
        lecturer = Academic.get_lecturer_with_programs(user_id)
        unassigned_programs = Academic.list_unassigned_programs(user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Program assigned successfully")
         |> assign(:lecturer, lecturer)
         |> assign(:unassigned_programs, unassigned_programs)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to assign program")}
    end
  end

  def handle_event("remove_program", %{"user_id" => user_id, "program_id" => program_id}, socket) do
    case Academic.remove_lecturer_from_program(user_id, program_id) do
      :ok ->
        lecturer = Academic.get_lecturer_with_programs(user_id)
        unassigned_programs = Academic.list_unassigned_programs(user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Program removed successfully")
         |> assign(:lecturer, lecturer)
         |> assign(:unassigned_programs, unassigned_programs)}
    end
  end

  def handle_event("set_primary", %{"user_id" => user_id, "program_id" => program_id}, socket) do
    import Ecto.Query
    
    # First, reset all primary flags for this user
    query = from(lp in LecturerProgram, where: lp.user_id == ^user_id)
    Register.Repo.update_all(query, set: [is_primary: false])

    # Then set the selected program as primary
    query = from(lp in LecturerProgram, 
      where: lp.user_id == ^user_id and lp.program_id == ^program_id)
    Register.Repo.update_all(query, set: [is_primary: true])

    lecturer = Academic.get_lecturer_with_programs(user_id)

    {:noreply,
     socket
     |> put_flash(:info, "Primary program updated")
     |> assign(:lecturer, lecturer)}
  end
end
