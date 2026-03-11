# Cannery - Claude Code Instructions

## Tidewave MCP

Tidewave is installed and runs at `http://localhost:4000/tidewave/mcp` when the dev server is up.

The MCP server is configured in `.mcp.json` and auto-connects. Use `/mcp` to verify the connection.

Available tools:
- `get_docs` — look up module/function documentation
- `get_source_location` — navigate directly to source code
- `get_models` — discover modules and their locations
- `project_eval` — evaluate code in the running app context
- `execute_sql_query` — run database queries
- `get_logs` — access server logs
- `search_package_docs` — search Hexdocs

Prefer these tools over reading source files manually when working in this project.
