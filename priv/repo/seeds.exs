# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Register.Repo.insert!(%Register.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Register.Accounts
alias Bcrypt

Accounts.register_user(%{
  email: "admin@gmail.com",
  password: "password06foradmin",
  role: "super_user"
})
