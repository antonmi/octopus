# Octopus
## Declarative Interface Translation
## Specification -> Elixir Code -> API

### The problem
As an application engineer, I need a simple way of interfacing
with programs/services that provide the required functionality.
The conventional approach to the problem is creating client libraries.
Such a library usually does three simple things:

1. Translate data structures provided by the programming language (e.g. Elixir) to data required by another program (e.g. GET request to a URL with params).
2. Call the program (e.g. make HTTP request).
3. Translate the result (e.g. JSON response) to the language's data structures.

However, each such translation must be explicitly coded. And this leads to a decent amount of boilerplate code.

### The idea
These kinds of translations can be expressed in declarative way via specifications expressed as a data structure. 

### The solution
The specification can be provided using a JSON data structure that describes the interface to a service.
The client library code is generated from the specification.
The JSON is chosen as the specification language because it is easy to translate to Elixir data structures:
JSON objects are translated to maps, JSON arrays are translated to lists, etc.

Consider a simple example. Let's say we are going to use the [Agify](https://agify.io/) service. It predicts age of a person by name.
To use it we need to send a simple HTTP get request to it and take the age data from the response.

The JSON specification for the service would be:
```json
{
  "name": "agify",
  "client": {
    "module": "OctopusClientHttpFinch",
    "start": {
      "base_url": "https://api.agify.io/"
    }
  },
  "interface": {
    "age_for_name": {
      "input": {
        "name": {"type": "string"}
      },
      "prepare": {
        "method": "GET",
        "path": "/",
        "params": {
          "name": "args['name']"
        }
      },
      "call": {
        "parse_json_body": true
      },
      "transform": {
        "age": "get_in(args, ['body', 'age'])"
      },
      "output": {
        "age": {"type": "number"}
      }
    }
  }
}
```
First, it says how what kind of client will be used - `OctopusClientHttpFinch`.
This is a low-level client that does basic communication with the HTTP API, and the module must exist in you app either as dependency or just a module in your code.
See the [OctopusClientHttpFinch](apps/octopus_client_http_finch/lib/octopus_client_http_finch.ex) and see the [Clients](#clients) section.

Second, it describes the interface of the service. In this case it has only one function - `age_for_name`.
There are 5 **optional** steps in the interface definition:
1. `input` - describes the input data structure. If specified, the input data is validated against it. Octopus uses [JSON Schema](https://json-schema.org/) for data definition and validation.
2. `prepare` - describes how the transformations needed to be done to the input data to make it ready for the call: path, method, params, headers, etc.
3. `call` - configures the actual call to the service. Here it just says that the response body should be parsed as JSON.
4. `transform` - describes how the result of the call should be transformed. In this case it just takes the `name` field from the response body.
5. `output` - describes the output data structure. The output data is validated against it.

The definition can also be provided as an Elixir data structure:
```elixir
definition = %{
  "client" => %{
    "module" => "OctopusClientHttpFinch",
    "start" => %{"base_url" => "https://api.agify.io/"}
  },
  "interface" => %{
    "age_for_name" => %{
      "input" => %{"name" => %{"type" => "string"}},
      "prepare" => %{
        "method" => "GET",
        "params" => %{"name" => "args['name']"},
        "path" => "/"
      },
      "call" => %{"parse_json_body" => true},
      "transform" => %{"age" => "get_in(args, ['body', 'age'])"},
      "output" => %{"age" => %{"type" => "number"}}
    }
  },
  "name" => "agify"
}
```
Please note that strings are used as keys in the input data structure. The idea is to close to the JSON as possible, and JSON doesn't have atom type.

### Transformations
There are two steps in the interface definition that transforms the data: `prepare` and `transform`.
You see 
```elixir
"params" => %{"name" => "args['name']"}
```
and
```elixir
"name" => "get_in(args, ['body', 'name'])"
```
The value-stings are evaluated as Elixir code. The `args` variable contains data from a previous step.
Only some `Kernel` functions and functions from `Access` module are available there.
There is also possible to add custom helpers for the transformation steps. See [Custom Helpers](#custom-helpers) section.

### The magic
Having the declaration above (and `OctopusClientHttpFinch` also) one can create the client **service** by running:
```elixir
Octopus.define(definition)
```
This will create the `Octpus.Services.Agify` module with a bunch of functions that are parameterized according to the specification.
One shouldn't use these function directly, but rather call them via `Octopus` API.
First, the service should be started:
```elixir
Octopus.start("agify")
```
Then, the service can be called:
```elixir
iex(1)> Octopus.call("agify", "age_for_name", %{"name" => "Anton"})
%{"age" => 50}
```
Again, note, that strings are used as keys in the input data structure.

See [`octopus_test.exs`](apps/octopus/test/octopus_test.exs) for other functions in Octopus.

### OctopusAgent
Since we translate the interface to JSON it becomes easy to interact with them via HTTP JSON API.
OctopusAgent is a simple HTTP JSON API server that can be used to interact with the services.
See the OctopusAgent [README.md](apps/octopus_agent/README.md) for more details.

### Clients
Clients are the low-level modules that do the actual communication with the service.
One can find the examples in the umbrella apps here:
- [octopus_client_http_finch](apps/octopus_client_http_finch)
- [octopus_client_cli_rambo](apps/octopus_client_cli_rambo)
- [octopus_client_postgrex](apps/octopus_client_postgrex)

You can use them as a dependency or just copy-paste the code to your project.
The client must implement three functions (see the [Octopus.Client](apps/octopus/lib/octopus/client.ex) behaviour):

Start:
```elixir
@spec start(map(), map(), atom()) :: {:ok, map()} | {:error, any()}
def start(args, configs, service_module) do
  # `args` comes from Octopus.start("my_service", args)
  # `configs` comes from the "start" section of the specification
  # `service_module` is the module of the defined service (like Octopus.Services.MyService) 
end
```
The returned map represents the state of the client. 
It will be passed to the `call` and `stop` functions.

Stop:
```elixir
@spec stop(map(), map(), any()) :: :ok | {:error, :not_found}
def stop(args, configs, state) do
  # `args` comes from Octopus.stop("my_service", args)
  # `configs` comes from the "stop" section of the specification
  # `state` is the map returned from the start function 
end
```

Call:
```elixir
@spec call(map(), map(), any()) :: {:ok, map()} | {:error, any()}
def call(args, configs, state) do
  # `args` comes from Octopus.call("my_service", "my_function", args)
  # `configs` comes from the "call" section of the specification
  # `state` is the map returned from the start function
end
```

### Custom Helpers
It is possible to add custom helpers for the transformation steps.
One can add list of helper modules to the `helpers` key in the specification:
```elixir
```json
{
  "name": "my_service",
  "helpers": ["MyCustomHelpers", "AnotherHelpers"],
  "client": ...,
  "interface": ...,
}
```
The modules must exist (be compiled) before the service is defined.
Functions from the modules will be available in the transformation steps.
If, for example, you have:
```elixir
defmodule MyCustomHelpers do
  def inc_by_one(number), do: number + 1
end
```
You can use the `inc_by_one` function in the transformation step:
```elixir
%{
"prepare" => %{"y" => "inc_by_one(args['x'])"},
"transform" => %{"z" => "inc_by_one(args)"},
}
```

