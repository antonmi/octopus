# Octopus

## Declarative Interface Translation

### Draft MVP, things will change significantly

### Motivation

### Declarative interface translation.
#### Specification -> Elixir Code -> API

Consider the following specification:

```json
{
  "name": "github",
  "client": {
    "module": "OctopusClientHttpFinch",
    "init": {
      "base_url": "https://api.github.com",
        "headers": {
          "Accept": "application/vnd.github+json"
        }
    }
  },
  "interface": {
    "find_users": {
      "input": {
        "username": {
          "type": "string"
        }
      },
      "prepare": {
        "method": "GET",
        "path": "/search/users",
        "params": {
          "q": "args['username']"
        }
      },
      "call": {
        "parse_json_body": true
      },
      "transform": {
        "total_count": "get_in(args, ['body', 'total_count'])",
        "users": "get_in(args, ['body', 'items'])"
      },
      "output": {
        "total_count": {"type": "integer"},
        "users": {"type": "array"}
      }
    },
    "get_followers": {
      "input": {
        "username": {
          "type": "string"
        }
      },
      "prepare": {
        "method": "GET",
        "path": "'users/' <> args['sername'] <> '/followers'"
      },
      "call": {
        "parse_json_body": true
      },
      "transform": {
        "followers": "args['body']"
      },
      "output": {
        "followers": {"type": "array"}
      }
    }
  }
}

```
