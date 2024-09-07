defmodule DemoTelemetry.UsersTest do
  use DemoTelemetry.RepoCase

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
end
