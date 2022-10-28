# Octopus

**Declarative remote routine execution and interface mapping**

## Draft MVP, things will change significantly

### Motivation
There are lots of applications have been created.

They are being run in a different way: from a simple unix command, to a server in the cloud.

They have various interfaces: from simple binary input/output for cli apps, to a rich HTTP JSON API.

Let's use term "Remote Routine" (RR) as a general term.

As a software engineer I want to utilize existing software in a simple and uniform way.

That means, I want easily declare the rules of how to run RR and how to interact with it.

### Declarative interface mapping.
#### Specification -> Elixir Code -> API

Consider the following specification:

```json
{
   "name":"agify",
   "interface":{
      "type":"json_api",
      "age_for_name":{
         "call":{
            "method":"GET",
            "path":"/",
            "url":"https://api.agify.io"
         },
         "input":{
            "args":{
               "name":null
            }
         },
         "output":"map"
      }
   }
}
```

Other examples of definitions can be found here: [definitions](apps/octopus/test/definitions.ex)

The specification declares the interface for communication with the "agify" service.

After running 
```elixir
Octopus.Service.define(definition)
```
magic happens: 
- a new Elixir module appears: `Octopus.Service.Agify` ("name": "agify").
- there is `age_for_name/1` function defined in the module, which takes `%{"name" => "AnyName"}` as input and return `{:ok, map}`

So one can call
```elixir
iex> Octopus.Service.Agify.age_for_name(%{"name" => "Anton"})
{:ok, %{"age" => 55, "count" => 23328, "name" => "Anton"}}
```

See [service_test](apps/octopus/test/service_test.exs)

There is also JSON API interface for definitions and evaluations:
```sh
cd apps/api
iex -S mix
```
Server listens 4001 port by default.

Then on can call
```
POST /define
with definition payload
```
then access the defined routine via
```
POST /services/agify/age_for_name/
with {"name": "Anton"} payload 
```
and you'll get the response:
```json
{"age": 55, "count": 23328, "name": "Anton"}
```

See [requests_test](apps/api/test/requests_test.exs)

### Declarative routine execution.
One can also specify how the routine should be run.

For example:

```json
{
  "name": "json_server.v1",
  "execution": {
    "type": "process",
    "start": {
      "command": "json-server",
      "args": ["-w", "db.json"]
    },
  },
  "interface": {...}
}
```

See [definitions](apps/octopus/test/definitions.ex).


