defmodule HexMcp.McpServer do
  use MCPServer

  require Logger

  @protocol_version "2024-11-05"

  @impl true
  def handle_ping(request_id) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: "pong"
     }}
  end

  @impl true
  def handle_initialize(request_id, params) do
    case validate_protocol_version(params["protocolVersion"]) do
      :ok ->
        {:ok,
         %{
           jsonrpc: "2.0",
           id: request_id,
           result: %{
             protocolVersion: @protocol_version,
             capabilities: %{
               tools: %{
                 listChanged: false
               }
             },
             serverInfo: %{
               name: "Dependency Version MCP Server",
               version: "0.1.0"
             },
             tools: tools_list()
           }
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def handle_list_tools(request_id, _params) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         tools: tools_list()
       }
     }}
  end

  @impl true
  def handle_call_tool(
        request_id,
        %{"name" => "hex_version_info", "arguments" => %{"package_name" => package_name}}
      ) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         content: [
           %{
             type: "text",
             text: get_hex_package_version(package_name)
           }
         ]
       }
     }}
  end

  @impl true
  def handle_call_tool(
        request_id,
        %{"name" => "rubygems_version_info", "arguments" => %{"package_name" => package_name}}
      ) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         content: [
           %{
             type: "text",
             text: get_rubygems_package_version(package_name)
           }
         ]
       }
     }}
  end

  @impl true
  def handle_call_tool(
        request_id,
        %{"name" => "npm_version_info", "arguments" => %{"package_name" => package_name}}
      ) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         content: [
           %{
             type: "text",
             text: get_npm_package_version(package_name)
           }
         ]
       }
     }}
  end

  @impl true
  def handle_call_tool(
        request_id,
        %{"name" => "pypi_version_info", "arguments" => %{"package_name" => package_name}}
      ) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         content: [
           %{
             type: "text",
             text: get_pypi_package_version(package_name)
           }
         ]
       }
     }}
  end

  def handle_call_tool(request_id, %{"name" => unknown_tool}) do
    {:error,
     %{
       jsonrpc: "2.0",
       id: request_id,
       error: %{
         code: -32601,
         message: "Method not found",
         data: %{
           name: unknown_tool
         }
       }
     }}
  end

  defp validate_package_name(package_name, package_type) do
    config = %{
      hex: %{min_size: 2, max_size: 60, pattern: ~r/^[a-z0-9\-\_\.]+$/},
      rubygems: %{min_size: 2, max_size: 60, pattern: ~r/^[a-z0-9\-\_\.]+$/},
      pypi: %{min_size: 1, max_size: 100, pattern: ~r/^[a-z0-9\-\_\.]+$/},
      npm: %{min_size: 2, max_size: 214, pattern: ~r/^[@a-z0-9\-\_\.\/]+$/}
    }

    rules = config[package_type]

    with true <- is_binary(package_name),
         true <- byte_size(package_name) >= rules.min_size,
         true <- byte_size(package_name) <= rules.max_size,
         true <- package_name =~ rules.pattern do
      {:ok, package_name}
    else
      false -> {:error, "Invalid package name"}
    end
  end

  defp get_package_version(package_name, package_type) do
    config = %{
      hex: %{
        url: "https://hex.pm/api/packages/",
        version_extractor: fn decoded -> hd(decoded["releases"])["version"] end,
        error_prefix: "hex"
      },
      rubygems: %{
        url: "https://rubygems.org/api/v1/versions/",
        url_suffix: "/latest.json",
        version_extractor: fn decoded -> decoded["version"] end,
        error_prefix: "RubyGems"
      },
      pypi: %{
        url: "https://pypi.org/pypi/",
        url_suffix: "/json",
        version_extractor: fn decoded -> decoded["info"]["version"] end,
        error_prefix: "PyPI"
      },
      npm: %{
        url: "https://registry.npmjs.org/",
        url_suffix: "/latest",
        version_extractor: fn decoded -> decoded["version"] end,
        error_prefix: "NPM"
      }
    }

    rules = config[package_type]

    case validate_package_name(package_name, package_type) do
      {:ok, name} ->
        try do
          url = rules.url <> name <> Map.get(rules, :url_suffix, "")

          case HTTPoison.get(url) do
            {:ok, %HTTPoison.Response{body: body}} ->
              decoded = Jason.decode!(body)
              rules.version_extractor.(decoded)

            {:error, _} ->
              "Unknown package"
          end
        rescue
          error ->
            Logger.error("Error getting #{rules.error_prefix} package version: #{inspect(error)}")
            "An error occurred"
        end

      {:error, reason} ->
        reason
    end
  end

  defp get_hex_package_version(package_name), do: get_package_version(package_name, :hex)

  defp get_rubygems_package_version(package_name),
    do: get_package_version(package_name, :rubygems)

  defp get_pypi_package_version(package_name), do: get_package_version(package_name, :pypi)

  defp get_npm_package_version(package_name), do: get_package_version(package_name, :npm)

  defp tools_list() do
    [
      %{
        name: "hex_version_info",
        description:
          "Returns the latest version of the hex package. Use it to check for the latest hex package version when installing new Elixir dependencies",
        inputSchema: %{
          type: "object",
          required: ["package_name"],
          properties: %{
            package_name: %{
              type: "string",
              description: "The name of the hex package"
            }
          }
        },
        outputSchema: %{
          type: "object",
          required: ["version"],
          properties: %{
            version: %{
              type: "string",
              description: "The latest version of the hex package"
            }
          }
        }
      },
      %{
        name: "rubygems_version_info",
        description:
          "Returns the latest version of the Ruby gem. Use it to check for the latest gem version when installing new Ruby dependencies",
        inputSchema: %{
          type: "object",
          required: ["package_name"],
          properties: %{
            package_name: %{
              type: "string",
              description: "The name of the Ruby gem"
            }
          }
        },
        outputSchema: %{
          type: "object",
          required: ["version"],
          properties: %{
            version: %{
              type: "string",
              description: "The latest version of the Ruby gem"
            }
          }
        }
      },
      %{
        name: "pypi_version_info",
        description:
          "Returns the latest version of the Python package. Use it to check for the latest PyPI package version when installing new Python dependencies",
        inputSchema: %{
          type: "object",
          required: ["package_name"],
          properties: %{
            package_name: %{
              type: "string",
              description: "The name of the Python package"
            }
          }
        },
        outputSchema: %{
          type: "object",
          required: ["version"],
          properties: %{
            version: %{
              type: "string",
              description: "The latest version of the Python package"
            }
          }
        }
      },
      %{
        name: "npm_version_info",
        description:
          "Returns the latest version of the NPM package. Use it to check for the latest NPM package version when installing new JavaScript dependencies",
        inputSchema: %{
          type: "object",
          required: ["package_name"],
          properties: %{
            package_name: %{
              type: "string",
              description: "The name of the NPM package"
            }
          }
        },
        outputSchema: %{
          type: "object",
          required: ["version"],
          properties: %{
            version: %{
              type: "string",
              description: "The latest version of the NPM package"
            }
          }
        }
      }
    ]
  end
end
