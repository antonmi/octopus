# OctopusAgent

## HTTP JSON API for Octopus

First, check the root [README](../../README.md) for more details.

The agent provides a simple HTTP JSON API to interact with the services.
One can deploy the agent as a service into the existing system and use it to interact with the other services.

### Configuration
OctopusAgent starts a web server that listens to the port specified in the `PORT` environment variable (4001 by default).

### API

- **POST /define** with JSON service definition
- **POST /start/:name** with JSON start options
- **POST /call/:name/:function** with JSON arguments
- **POST /stop/:name** with JSON start options
- **POST (or GET) /status/:name**
- **POST /delete/:name**

See [requests_test.exs](test/requests_test.exs) for more examples.


