defmodule DemoTelemetry.UsersTest do
  use DemoTelemetry.RepoCase

  import DemoTelemetry.Factory
  import TelemetryTestHelper

  alias DemoTelemetry.Users

  @primary_repo_event [:demo_telemetry, :primary, :query]

  describe "create/1" do
    test "create a user - happy path", %{test: test} do
      attach(@primary_repo_event, test)

      Users.create("TestUser")

      assert_receive({:telemetry_event, data})
      assert %{event_name: @primary_repo_event, measurements: _, metadata: metadata} = data
      assert "create_user" == ecto_event_name(metadata)
    end
  end

  describe "ex_machina test" do
    test "ensure ecto telemetry events allow naming db interactions with ex_machina", %{test: test} do
      attach(@primary_repo_event, test)

      # Call ex_machina's insert/3 function and name this db interaction "ex_machina"
      insert(:user, %{}, telemetry_options: %{name: "ex_machina"})

      assert_receive({:telemetry_event, data})
      assert %{event_name: @primary_repo_event, measurements: _, metadata: metadata} = data
      assert "ex_machina" == ecto_event_name(metadata)
    end
  end
end
