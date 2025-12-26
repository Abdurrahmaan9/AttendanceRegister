# defmodule Register.Academic.LecturerProgram do
#   use Ecto.Schema
#   import Ecto.Changeset

#   schema "lecturer_programs" do
#     field :is_primary, :boolean, default: false
#     belongs_to :user, Register.Accounts.User
#     belongs_to :program, Register.Academic.Program

#     timestamps()
#   end

#   @doc false
#   def changeset(lecturer_program, attrs) do
#     lecturer_program
#     |> cast(attrs, [:user_id, :program_id, :is_primary])
#     |> validate_required([:user_id, :program_id])
#     |> unique_constraint([:user_id, :program_id], name: :user_id_program_id_unique_index)
#   end
# end
