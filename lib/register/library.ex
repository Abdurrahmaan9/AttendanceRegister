defmodule Register.Library do
  @moduledoc """
  The Library context.
  """

  import Ecto.Query, warn: false
  alias Register.Repo

  alias Register.Library.LibraryBoard
  alias Register.Library.LibraryResource

  def list_library_boards do
    LibraryBoard
    |> preload(:resources)
    |> Repo.all()
  end

  def get_library_board!(id), do: Repo.get!(LibraryBoard, id) |> Repo.preload(:resources)

  def create_library_board(attrs \\ %{}) do
    %LibraryBoard{}
    |> LibraryBoard.changeset(attrs)
    |> Repo.insert()
  end

  def update_library_board(%LibraryBoard{} = library_board, attrs) do
    library_board
    |> LibraryBoard.changeset(attrs)
    |> Repo.update()
  end

  def delete_library_board(%LibraryBoard{} = library_board) do
    Repo.delete(library_board)
  end

  def change_library_board(%LibraryBoard{} = library_board, attrs \\ %{}) do
    LibraryBoard.changeset(library_board, attrs)
  end

  def list_library_resources do
    Repo.all(LibraryResource)
  end

  def get_library_resource!(id), do: Repo.get!(LibraryResource, id)

  def create_library_resource(attrs \\ %{}) do
    %LibraryResource{}
    |> LibraryResource.changeset(attrs)
    |> Repo.insert()
  end

  def update_library_resource(%LibraryResource{} = library_resource, attrs) do
    library_resource
    |> LibraryResource.changeset(attrs)
    |> Repo.update()
  end

  def delete_library_resource(%LibraryResource{} = library_resource) do
    Repo.delete(library_resource)
  end

  def change_library_resource(%LibraryResource{} = library_resource, attrs \\ %{}) do
    LibraryResource.changeset(library_resource, attrs)
  end
end
