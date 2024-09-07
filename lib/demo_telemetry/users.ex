defmodule DemoTelemetry.Users do
  @moduledoc """
  High level API for users
  """

  alias DemoTelemetry.Users.Dml

  @primary_repo DemoTelemetry.Database.Repo

  @spec create(String.t()) :: Ecto.Schema.t() | Ecto.Changeset.t()
  def create(name) when is_binary(name) do
    Dml.create_user(@primary_repo, %{name: name})
  end
end
