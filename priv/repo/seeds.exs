alias Register.Accounts
alias Register.Students
alias Register.Repo

# Create admin user
case Accounts.register_user(%{
  email: "admin@gmail.com",
  password: "admin@123",
  first_name: "Admin",
  last_name: "User"
}) do
  {:ok, admin_user} ->
    {:ok, _} = Accounts.assign_role(admin_user, "admin")
    IO.puts("✓ Created admin user: admin@example.com (password: admin@123)")
  {:error, _} ->
    IO.puts("Admin user already exists")
end

# Create lecturer user
case Accounts.register_user(%{
  email: "lecturer@gmail.com",
  password: "lecturer@123",
  first_name: "John",
  last_name: "Lecturer"
}) do
  {:ok, lecturer_user} ->
    {:ok, _} = Accounts.assign_role(lecturer_user, "lecturer")
    IO.puts("✓ Created lecturer user: lecturer@example.com (password: lecturer@123)")
  {:error, _} ->
    IO.puts("Lecturer user already exists")
end

# Create student users
student_data = [
  %{email: "student1@example.com", first_name: "Alice", last_name: "Smith", program: "Computer Science"},
  %{email: "student2@example.com", first_name: "Bob", last_name: "Johnson", program: "Information Technology"},
  %{email: "student3@example.com", first_name: "Carol", last_name: "Williams", program: "Computer Science"}
]

Enum.each(student_data, fn data ->
  case Students.create_student(Map.put(data, :password, "student@123")) do
    {:ok, _student} ->
      IO.puts("✓ Created student: #{data.email} (password: student@123)")
    {:error, _} ->
      IO.puts("Student already exists: #{data.email}")
  end
end)

IO.puts("\n✓ Database seeding completed!")
