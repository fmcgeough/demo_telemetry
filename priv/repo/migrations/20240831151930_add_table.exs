defmodule DemoTelemetry.Database.Repo.Migrations.AddTable do
  use Ecto.Migration

  def change do
      create table(:users) do
        add :name, :string, size: 255

        timestamps()
      end
  end
end
