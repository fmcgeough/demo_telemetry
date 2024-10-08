defmodule DemoTelemetry.Factory do
  @moduledoc """
  Provide ability to easily create test data
  """
  # with Ecto
  use ExMachina.Ecto, repo: DemoTelemetry.Database.Repo

  alias DemoTelemetry.Database.Schema.User

  def user_factory(attrs) do
    %User{name: Faker.Person.name()} |> merge_attributes(attrs)
  end
end
