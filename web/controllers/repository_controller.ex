defmodule Beanie.RepositoryController do
  use Beanie.Web, :controller

  alias Beanie.Repository

  def index(conn, params) do
    case repository_list(params["update"]) do
      {:ok, repositories} ->
        conn
        |> put_flash(:info, "Repository list updated")
        |> render("index.html", repositories: repositories)
      {:error, repositories} ->
        conn
        |> put_flash(:error, "Error fetching repositories")
        |> render("index.html", repositories: repositories)
    end
  end

  def create(conn, %{"repository" => repository_params}) do
    changeset = Repository.changeset(%Repository{}, repository_params)

    case Repo.insert(changeset) do
      {:ok, _repository} ->
        conn
        |> put_flash(:info, "Repository created successfully.")
        |> redirect(to: repository_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    repository = fetch_repository(id)
    render(conn, "show.html", repository: repository)
  end

  def edit(conn, %{"id" => id}) do
    repository = Repo.get!(Repository, id)
    changeset = Repository.changeset(repository)
    render(conn, "edit.html", repository: repository, changeset: changeset)
  end

  def update(conn, %{"id" => id, "repository" => repository_params}) do
    repository = Repo.get!(Repository, id)
    changeset = Repository.changeset(repository, repository_params)

    case Repo.update(changeset) do
      {:ok, repository} ->
        conn
        |> put_flash(:info, "Repository updated successfully.")
        |> redirect(to: repository_path(conn, :show, repository))
      {:error, changeset} ->
        render(conn, "edit.html", repository: repository, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    repository = Repo.get!(Repository, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(repository)

    conn
    |> put_flash(:info, "Repository deleted successfully.")
    |> redirect(to: repository_path(conn, :index))
  end

  defp repository_list("true") do
    %{"repositories" => from_docker} = Beanie.RegistryAPI.catalog(Beanie.registry)
    Beanie.Repository.Query.update_list(from_docker)
    # TODO refresh repository listing, then fetch from db
    {:ok, Repo.all(Repository)}
  end
  defp repository_list(_) do
    {:ok, Repo.all(Repository)}
  end

  defp fetch_repository(id) do
    repo = Repo.get!(Repository, id)
    %{"tags" => tags} = Beanie.RegistryAPI.tag_list(Beanie.registry, repo.name)
    %{ repo | tags: tags }
  end
end
