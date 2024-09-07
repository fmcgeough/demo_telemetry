# DemoTelemetry

This is a github repo I setup to demonstrate telemetry event generation for the
[Elixir](https://elixir-lang.org/) language's [ecto library](https://hexdocs.pm/ecto/Ecto.html).

Note: this demonstrates a number of aspects of Ecto Telemetry. It's fine to submit a PR for this
repo if you want to add to what is demonstrated (or fix some problem).

See the blog post [Ecto Telemetry](https://fmcgeough.github.io/blog/2024/ecto-telemetry/) for more information.

## Demonstrating Ecto Telemetry

The code in this app demonstrates some features of ecto telemetry that you should
be aware of. You can try out these features in iex. You need to have a Postgresql
test instance that the code can connect to. Examine the `config/config.exs` file to
see if you want to adjust the user / password. Here are steps to get going:

```
$ git clone https://github.com/fmcgeough/demo_telemetry
$ cd demo_telemetry
$ mix deps.get && mix ecto.create --quiet && mix ecto.migrate --quiet && iex -S mix
```

You can follow along after that with the sections below.

### Simple Tests

This shows the event data (including the event name) received when
interacting with each of the three repos defined in the project.

```
$ iex -S mix
iex> DemoTelemetry.Database.Repo.all(User)
```
![Primary](guides/primary.png)

```
iex> DemoTelemetry.Database.ReaderRepo.all(User)
```
![Replica](guides/replica.png)

```
iex> DemoTelemetry.Database.OtherRepo.all(User)
```
![Other](guides/other.png)

### Transactions and Ecto.Multi

```
iex> alias Ecto.Multi
iex> Multi.new() |> Multi.run(:test, fn _repo, _args -> {:ok, nil} end) |> Repo.transaction()
```

![Multi](guides/multi_commit.png)

```
iex> alias Ecto.Multi
iex> Multi.new() |> Multi.run(:test, fn _repo, _args -> {:error, :badness} end) |> Repo.transaction()
```

![Multi](guides/multi_rollback.png)

### Identify Your Query

When you execute your query you can pass in telemetry_options as a final parameter. This lets
you pass on important information to your metrics handler. It's very important to do so. It
allows you to easily identify what SQL was executed (without attempting to parse the query
passed in the metadata). Note that transaction related operations - begin, commit, rollback - cannot
be named in this way. You will need to explicitly look for those strings in order to identify
them in your metrics.

iex> Repo.all(User, telemetry_options: %{name: "all_users"})

![Query Id](guides/query_id.png)

### Telemetry Event

Another option available is to use `:telemetry_event` when the database operation is done.
Personally I've never used this but it is available. The event generated by ecto_sql uses
the exact name that you pass as the `:telemetry_event` (it doesn't append `[:query]` to the
event name). That means that if you want to receive the event you must include the name
in the list of events you're listening for in call to `:telemetry.attach_many`.

Here's an example using `:telemetry_event`.

```
iex> Repo.all(User, telemetry_event: [:demo_telemetry, :test_telemetry_event])
```

The generated event name will be: `[:demo_telemetry, :test_telemetry_event]`.

![Telemetry Event](guides/telemetry_event.png)

## Unit Tests and Ecto Telemetry Events

The project includes a "helper" module in test/support called `TelemetryTestHelper`.
This lets a unit test attach to telemetry events (using its test name) and then
check that it receives a telemetry event that has a query identifier (its named).
There's an example test showing how this is used.

```
    test "create a user - happy path", %{test: test} do
      attach(@primary_repo_event, test)

      Users.create("TestUser")

      assert_receive({:telemetry_event, data})
      assert %{event_name: @primary_repo_event, measurements: _, metadata: metadata} = data
      assert "create_user" == ecto_event_name(metadata)
    end
```

The TelemetryTestHelper module is imported into the unit tests. It provides:

- attach/2 - to allow the unit test to indicate it wants to check on the generation of a single
  event
- attach_many/2  - to allow the unit test to indicate it wants to check on the generation of multiple events

The TelemetryTestHelper module has its own event handler. It gets the telemetry event and then sends
a message to the unit test as a tuple `{:telemetry_event, map()}`. The map contains all the telemetry
related info (event_name, measurements and metadata).

The TelemetryTestHelper module has a function - `ecto_event_name/1` - that extracts the db query
name (if present) from the metadata. This allows the unit test to ensure that the name is set.

The TelemetryTestHelper module automatically detaches the event handler when the test completes. This
is very important. If no detach is done then the event will continue to generate and send messages
when a different unit test is running.
