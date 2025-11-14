defmodule Register.Academic.LecturerCourse do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lecturer_courses" do
    field :is_primary, :boolean, default: false
    belongs_to :user, Register.Accounts.User
    belongs_to :course, Register.Courses.Course

    timestamps()
  end

  @doc false
  def changeset(lecturer_course, attrs) do
    lecturer_course
    |> cast(attrs, [:user_id, :course_id, :is_primary])
    |> validate_required([:user_id, :course_id])
    |> unique_constraint([:user_id, :course_id], name: :user_id_course_id_unique_index)
  end
end
