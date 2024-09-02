defmodule DemoTelemetry.Database.Schema.User do
  @moduledoc """
  users table schema
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  schema "users" do
    field(:name, :string)

    timestamps()
  end

  def changeset(%User{} = user, params) do
    user
    |> cast(params, [:name])
  end
end
