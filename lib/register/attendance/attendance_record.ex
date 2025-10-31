defmodule Register.Attendance.AttendanceRecord do
  use Ecto.Schema
  import Ecto.Changeset

  schema "attendance_records" do
    field :module_code, :string
    field :module_name, :string
    field :session_date, :date
    field :method, :string, default: "otp"
    field :first_name, :string
    field :last_name, :string
    belongs_to :student, Register.Accounts.User
    belongs_to :course, Register.Courses.Course

    timestamps()
  end

  @doc false
  def changeset(attendance_record, attrs) do
    attendance_record
    |> cast(attrs, [:module_code, :module_name, :session_date, :method, :student_id, :course_id, :first_name, :last_name])
    |> validate_required([:module_code, :module_name, :session_date, :student_id, :course_id])
    |> unique_constraint([:student_id, :course_id, :module_code, :session_date], name: "attendance_records_unique_student_course_module_session_idx", message: "attendance already recorded for this session")
  end
end
