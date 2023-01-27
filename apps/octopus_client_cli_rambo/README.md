# OctopusClientCliRambo

**Execute unix commands**

### Example

```json
{
  "name": "files",
  "client": {
    "module": "OctopusClientCliRambo",
    "start": {}
  },
  "interface": {
    "ls": {
      "input": {
        "path": {"type": "string"}
      },
      "prepare": {
        "command": "ls",
        "input": "args['path']"
      },
      "call": {
        "split_by_newline": true
      },
      "transform": {
        "status": "args['status']",
        "output": "args['out']"
      },
      "output": {
        "status": {"type": "number"},
        "output": {"type": "array"}
      }
    }
  }
}
```
