defmodule DemoTelemetry.Factory do
  @moduledoc """
  Provide ability to easily create test data
  """
  # with Ecto
  use ExMachina.Ecto, repo: DemoTelemetry.Database.Repo

  # without Ecto
  use ExMachina

  alias DemoTelemetry.Database.Schema.User

  def user_factory do
    %User{name: Faker.Person.name()}
  end
end
