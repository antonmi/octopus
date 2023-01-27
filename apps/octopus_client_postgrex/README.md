# OctopusClientPostgrex

**Postgres client for Octopus**

### Example

```json
{
  "name": "users",
  "client": {
    "module": "OctopusClientPostgrex",
    "start": {
      "host": "localhost",
      "port": "5432",
      "username": "postgres",
      "password": "postgres",
      "database": "octopus_test"
    }
  },
  "interface": {
    "all": {
      "input": {},
      "prepare": {
        "statement": "SELECT * FROM users",
        "params": []
      },
      "call": {
        "opts": {
          "timeout": 100
        }
      },
      "transform": {
        "columns": "args['columns']",
        "num_rows": "args['num_rows']",
        "rows": "args['rows']"
      },
      "output": {
        "columns": {"type": "array", "items": {"type": "string"}},
        "num_rows": {"type": "integer"},
        "rows": {"type": "array"}
      }
    },
    "insert": {
      "input": {
        "name": {"type": "string"},
        "age": {"type": "integer"}
      },
      "prepare": {
        "statement": "INSERT INTO users (name, age) VALUES ($1, $2) RETURNING id",
        "params": ["args['name']", "args['age']"]
      },
      "call": {
        "opts": {
          "timeout": 100
        }
      },
      "transform": {
        "id": "get_in(args['rows'], [Access.at(0), Access.at(0)])"
      },
      "output": {
        "id": {"type": "integer"}
      }
    },
    "find": {
      "input": {
        "id": {"type": "integer"}
      },
      "prepare": {
        "statement": "SELECT * FROM users WHERE id = $1",
        "params": ["args['id']"]
      },
      "transform": {
        "id": "get_in(args['rows'], [Access.at(0), Access.at(0)])",
        "name": "get_in(args['rows'], [Access.at(0), Access.at(1)])",
        "age": "get_in(args['rows'], [Access.at(0), Access.at(2)])"
      },
      "output": {
        "id": {"type": "integer"},
        "name": {"type": "string"},
        "age": {"type": "integer"}
      }
    }
  }
}
```
