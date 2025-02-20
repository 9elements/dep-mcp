# Package Version MCP Server

A Model Context Protocol (MCP) server that provides real-time package version information to AI tools like Cursor. This service helps ensure that AI-assisted development uses the correct and most up-to-date package versions when adding dependencies to your projects.

## Supported Package Managers

- **Hex** - For Elixir projects ([hex.pm](https://hex.pm))
- **RubyGems** - For Ruby projects ([rubygems.org](https://rubygems.org))
- **PyPI** - For Python projects ([pypi.org](https://pypi.org))
- **NPM** - For JavaScript projects ([npmjs.com](https://www.npmjs.com))

## What is MCP?

The Model Context Protocol (MCP) is an open protocol that standardizes how applications provide context to Large Language Models (LLMs). Think of it like a USB-C port for AI applications. For more information about MCP, visit the [official documentation](https://modelcontextprotocol.io/introduction).

## Using with Cursor

Cursor supports MCP servers out of the box. To get accurate package version suggestions in your projects, add this server to your Cursor configuration.

### Server URL

```
https://dep-mcp.9elements.com/sse
```

For detailed setup instructions, visit the [Cursor MCP documentation](https://docs.cursor.com/context/model-context-protocol#model-context-protocol).

## Development Setup

To start your Phoenix server locally:

1. Run `mix setup` to install and setup dependencies
2. Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
3. Visit [`localhost:4000`](http://localhost:4000) from your browser

## Disclaimer

While this service uses the official APIs provided by the respective package registries, we are not affiliated with or endorsed by any of them. The service is provided as-is without any warranty. Use at your own discretion.

## Production Deployment

For production deployment instructions, please refer to the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn More

- [Phoenix Framework Official Website](https://www.phoenixframework.org/)
- [Phoenix Documentation](https://hexdocs.pm/phoenix)
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- [Phoenix Forum](https://elixirforum.com/c/phoenix-forum)

## Credits

Built with ❤️ by [Daniel Hoelzgen](https://dhoelzgen.dev) from [9elements](https://9elements.com)

## Legal

- [Imprint](https://9elements.com/imprint)
- [Privacy Policy](https://9elements.com/imprint)
