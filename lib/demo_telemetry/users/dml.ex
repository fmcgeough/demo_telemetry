defmodule DemoTelemetry.Users.Dml do
  @moduledoc """
  Handle low level db activity
  """
  alias DemoTelemetry.Database.Schema.User

  @spec create_user(Ecto.Repo.t(), map()) :: Ecto.Schema.t() | Ecto.Changeset.t()
  def create_user(repo, params) do
    %User{}
    |> User.changeset(params)
    |> repo.insert(telemetry_options: %{name: "create_user"})
  end
end
