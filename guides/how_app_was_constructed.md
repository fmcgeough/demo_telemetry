## Steps

## Create Project

```
mix new --sup demo_telemetry
```

### Edit mix.exs and add dependencies

```
  {:telemetry, "1.3.0"},
  {:ecto_sql, "~> 3.12"},
  {:postgrex, ">= 0.0.0"},
  {:ex_machina, "~> 2.8", only: :test},
  {:faker, "~> 0.18.0", only: :test},
  {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
  {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
```

### Generate a Repo

```
mix ecto.gen.repo -r DemoTelemetry.Database.Repo
mix ecto.gen.repo -r DemoTelemetry.Database.ReaderRepo
mix ecto.gen.repo -r DemoTelemetry.Database.OtherRepo
```

### Edit config.exs

Modify `DemoTelemetry.Database.Repo` and `DemoTelemetry.Database.ReaderRepo`
to set the `telemetry_prefix`. This can be used to override what Ecto uses
by default. The `DemoTelemetry.Database.OtherRepo` Repo module is setup
to use the default. All of these connect to the same database.

```
config :demo_telemetry, DemoTelemetry.Database.Repo,
  database: "demo_telemetry_repo",
  username: "fmcgeough",
  hostname: "localhost",
  telemetry_prefix: [:demo_telemetry, :primary]

config :demo_telemetry, DemoTelemetry.Database.ReaderRepo,
  database: "demo_telemetry_repo",
  username: "fmcgeough",
  hostname: "localhost",
  telemetry_prefix: [:demo_telemetry, :replica]

config :demo_telemetry, DemoTelemetry.Database.OtherRepo,
  database: "demo_telemetry_repo",
  username: "fmcgeough",
  hostname: "localhost"

config :demo_telemetry,
  ecto_repos: [DemoTelemetry.Database.Repo]
```

### Generate a Migration

```
mix ecto.gen.migration add_table
```

Edit the resulting file to add a simple `users` table.

```
defmodule DemoTelemetry.Database.Repo.Migrations.AddTable do
  use Ecto.Migration

  def change do
      create table(:users) do
        add :name, :string, size: 255

        timestamps()
      end
  end
end
```

### Create a Schema module for the users table

```
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
```

### Create an .iex.exs file

```
alias DemoTelemetry.Database.Repo
alias DemoTelemetry.Database.ReaderRepo
alias DemoTelemetry.Database.OtherRepo
alias DemoTelemetry.Database.Schema.User
import Ecto.Query
```
