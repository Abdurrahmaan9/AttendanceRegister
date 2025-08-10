defmodule RegisterWeb.Admin.StudentsLive.Index do
  use RegisterWeb, :live_view
  alias Register.Students
  alias Register.Students.Student

  # Import CoreComponents for form inputs and UI components
  import Phoenix.Component

  @impl true
  def mount(_params, session, socket) do
    current_user = get_session_user(session)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:editing, nil)  # Add this line
      |> assign(:editing_id, nil)
      |> assign(:editing_student, nil)
      |> assign(:show_form, false)
      |> assign(:students, [])
      |> assign(:changeset, Students.change_student(%Student{}))

    if connected?(socket) do
      {:ok, assign(socket, :students, list_students())}
    else
      {:ok, socket}
    end
  end

  defp get_session_user(%{"user_token" => user_token}) when is_binary(user_token) do
    Register.Accounts.get_user_by_session_token(user_token)
  end

  defp get_session_user(_), do: nil

  @impl true
  def handle_params(params, _url, socket) do
    case socket.assigns.live_action do
      :new ->
        {:noreply,
          socket
          |> assign(:page_title, "New Student")
          |> assign(:show_form, true)
          |> assign(:editing_id, nil)
          |> assign(:editing_student, nil)
          |> assign(:changeset, Students.change_student(%Student{}))
        }
      :edit ->
        student = Students.get_student!(params["id"])
        {:noreply,
          socket
          |> assign(:page_title, "Edit Student")
          |> assign(:editing_id, student.id)
          |> assign(:editing_student, student)
          |> assign(:show_form, true)
          |> assign(:changeset, Students.change_student(student))
        }
      _ ->
        {:noreply,
          socket
          |> assign(:page_title, "Manage Students")
          |> assign(:editing_id, nil)
          |> assign(:editing_student, nil)
          |> assign(:show_form, false)
        }
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    student = Students.get_student!(id)
    {:ok, _} = Students.delete_student(student)

    {:noreply,
      socket
      |> update(:students, fn _ -> list_students() end)
      |> put_flash(:info, "Student deleted successfully")
    }
  end

  @impl true
  def handle_event("view_student", %{"id" => id}, socket) do
    # You can implement the view functionality here
    # For now, we'll just show a flash message
    {:noreply, put_flash(socket, :info, "Viewing student with ID: #{id}")}
  end

  @impl true
  def handle_event("edit_student", %{"id" => id}, socket) do
    student = Students.get_student!(id)
    changeset = Students.change_student(student)

    {:noreply,
      socket
      |> assign(:editing_id, student.id)
      |> assign(:editing_student, student)
      |> assign(:show_form, true)
      |> assign(:changeset, changeset)
    }
  end


  @impl true
  def handle_event("save", %{"student" => student_params}, socket) do
    case socket.assigns.editing do
      nil ->
        # Create new student
        case Students.create_student(student_params) do
          {:ok, _student} ->
            changeset = Students.change_student(%Student{})

            {:noreply,
              socket
              |> update(:students, fn _ -> list_students() end)
              |> assign(:changeset, changeset)
              |> assign(:editing, nil)
              |> assign(:editing_student, nil)
              |> assign(:show_form, false)
              |> put_flash(:info, "Student created successfully")
            }

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      student_id ->
        # Update existing student
        student = Students.get_student!(student_id)
        case Students.update_student(student, student_params) do
          {:ok, _student} ->
            changeset = Students.change_student(%Student{})

            {:noreply,
              socket
              |> update(:students, fn _ -> list_students() end)
              |> assign(:changeset, changeset)
              |> assign(:editing, nil)
              |> assign(:editing_student, nil)
              |> assign(:show_form, false)
              |> put_flash(:info, "Student updated successfully")
            }

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end
    end
  end

  @impl true
  def handle_event("validate", %{"student" => student_params}, socket) do
    changeset =
      %Student{}
      |> Students.change_student(student_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end


  @impl true
  def handle_event("new_student", _, socket) do
    changeset = Students.change_student(%Student{})
    {:noreply,
      socket
      |> assign(:editing_id, nil)
      |> assign(:editing_student, nil)
      |> assign(:show_form, true)
      |> assign(:changeset, changeset)
    }
  end

  @impl true
  def handle_event("cancel_edit", _, socket) do
    {:noreply,
      socket
      |> assign(:editing_id, nil)
      |> assign(:editing_student, nil)
      |> assign(:show_form, false)
      |> push_patch(to: Routes.students_index_path(socket, :index))
    }
  end

  @impl true
  def handle_event("delete_student", %{"id" => id}, socket) do
    student = Students.get_student!(id)
    {:ok, _} = Students.delete_student(student)

    {:noreply,
      socket
      |> assign(:students, list_students())
      |> put_flash(:info, "Student deleted successfully")
    }
  end

  defp list_students do
    Students.list_students()
  end


end
