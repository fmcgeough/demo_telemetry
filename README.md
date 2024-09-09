# DemoTelemetry

This is a github repo I setup to demonstrate telemetry event generation for the
[Elixir](https://elixir-lang.org/) language's [ecto library](https://hexdocs.pm/ecto/Ecto.html).

Note: this demonstrates a number of aspects of Ecto Telemetry. It's fine to submit a PR for this
repo if you want to add to what is demonstrated (or fix some problem).

See the blog post [Ecto Telemetry](https://fmcgeough.github.io/blog/2024/ecto-telemetry/) for more information.

## How and When are Telemetry Events Generated in Ecto?

Ecto is the library that Elixir developers use to interact with a relational database. Different
databases implement behaviour that allows Ecto to interact with different databases without having
all the code inside Ecto itself. So, for example, there is a
[postgrex](https://hexdocs.pm/postgrex/readme.html) library for Postgresql and a
[myxql](https://hexdocs.pm/myxql/readme.html) library for MySQL.

> Ecto is actually divided into two libraries: ecto and ecto_sql. This is because there are features
> in Ecto that are very useful for apps that do not use a relational database. For example, it is
> common to use Ecto to validate parameters for an API.

There are two telemetry events generated by Ecto (_note: a database adapter that plugs into Ecto could
have its own events defined so check its documentation_).

- a Repo initialization event, This occurs when an `Ecto.Repo` starts up (its generated by the
  `Ecto.Repo.Supervisor` module in the ecto library). This event always has the same event name. It
  is `[:ecto, :repo, :init]`.
- a Database Activity event. This is generated when a database interaction (select, insert, update,
  delete, etc, etc) occurs on a Repo connection. This event does not have a fixed name. It's naming
  is discussed below. This event is generally the only one that developers are interested in. It's
  metrics surrounding the app's interaction with the database. By capturing this data the developer
  can graph what queries are executing the most, which are the slowest queries, and other useful
  information. This is described in the Ecto documentation as an "Adapter Specific Event". This
  somewhat awkward naming is not that important. But I'll refer to it in this doc as a "Database
  Activity" event.

## Database Activity Event

Telemetry events are named. The name is is the first parameter passed to the `:telemetry.execute/3`
function. THe Repo Initialization event is hard-coded as `[:ecto, :repo, :init]`. The name used for
a Database Activity event requires more of an explanation.

By default, the Database Activity event uses your Repo module name as the event name (the name is
converted from camel-case to snake-case). Ecto concatenates this list with `[:query]`. So, if your
Ecto repo is called `MyApp.MyRepo` the Database Activity event name is `[:my_app, :my_repo, :query]`.

You can override this naming behaviour by setting the `telemetry_prefix` for your Ecto Repo in your
config files. For example, you might set the `telemetry_prefix` to `[:my_app, :ecto, :primary_db]`
for your primary Repo and the Database Activity event name is `[:my_app, :ecto, :primary_db,
:query]`. If you then set `[:my_app, :ecto, :replica_db]` for your replica database the event name
is `[:my_app, :ecto, :replica_db, :query]`.

## What is In A Database Activity Event?

The activity event passes the following measurements and metadata.

### Measurements

The :measurements map may include the following, all given in the :native time unit:

- :idle_time - the time the connection spent waiting before being checked out for the query
- :queue_time - the time spent waiting to check out a database connection
- :query_time - the time spent executing the query
- :decode_time - the time spent decoding the data received from the database
- :total_time - the sum of (queue_time, query_time, and decode_time)️

### Metadata

- :type - the type of the Ecto query. For example, for Ecto.SQL databases, it would be :ecto_sql_query
- :repo - the Ecto repository (the module name)
- :result - the query result
- :params - the dumped query parameters (formatted for database drivers like Postgrex)
- :cast_params - the casted query parameters (normalized before dumping)
- :query - the query sent to the database as a string
- :source - the source the query was made on (may be nil)
- :stacktrace - the stacktrace information, if enabled, or nil
- :options - extra options given to the repo operation under :telemetry_options

## Demonstrating Ecto Telemetry

The code in this app demonstrates some features of Ecto telemetry that you should
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

## Ex_machina and Ecto Telemetry Events

The [ex_machina](https://hexdocs.pm/ex_machina/readme.html) library provides the ability to generate
unit test data for the database. The unit test ends up calling an insert function provided by
ex_machina. Thankfully, the library provides a 3 argument insert where the last parameter are the
options passed to the Repo insert. This lets you pass in a name that can be differentiated from
the production code.

The reason that this is important is that if you are naming your db interactions (and you should
really do this) then you probably want to make sure that every interaction is named properly. However,
that means that you want to make sure that ex_machina isn't causing problems with any code you
write to validate that every db interaction is named. The easiest way to do this is to use the
`insert/3` function and pass in `:telemetry_options` to it. For example:

```
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
```
