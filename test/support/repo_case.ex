defmodule DemoTelemetry.RepoCase do
  @moduledoc """
  ExUnit module to use when testing Ecto.Repo related code
  """
  use ExUnit.CaseTemplate

  alias DemoTelemetry.Database.Repo, as: PrimaryRepo
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias DemoTelemetry.Database.Repo

      import Ecto
      import Ecto.Query
      import DemoTelemetry.RepoCase

      # and any other stuff
    end
  end

  setup tags do
    pid = Sandbox.start_owner!(PrimaryRepo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
    :ok
  end
end
