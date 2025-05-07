defmodule AI.Providers.OpenAICompatible.Provider do
  @moduledoc """
  Provider implementation for OpenAI-compatible APIs.

  This provider can be used to interact with any API that is compatible with the OpenAI API,
  such as Ollama, LMStudio, and others.
  """

  defstruct [
    :name,
    :base_url,
    :api_key,
    :headers,
    :query_params
  ]

  @doc """
  Creates a new OpenAI-compatible provider with the given options.

  ## Options
    * `:base_url` - The base URL of the API (required)
    * `:name` - The name of the provider (default: "openai-compatible")
    * `:api_key` - The API key to use for authentication (optional)
    * `:headers` - Additional headers to include in requests (optional)
  """
  def new(opts) do
    name = Map.get(opts, :name, "openai-compatible")
    api_key = Map.get(opts, :api_key)
    additional_headers = Map.get(opts, :headers, %{})

    # Check if base_url is provided
    raw_url =
      case Map.fetch(opts, :base_url) do
        {:ok, url} -> url
        :error -> raise ArgumentError, "base_url is required"
      end

    # Parse URL to extract base URL and query parameters
    {base_url, query_params} = parse_url(raw_url)

    # Remove trailing slash if present
    base_url = String.trim_trailing(base_url, "/")

    # Construct headers
    headers =
      if api_key do
        Map.put(additional_headers, "Authorization", "Bearer #{api_key}")
      else
        additional_headers
      end

    # Ensure headers are in the right format
    headers =
      if is_map(headers) do
        # Convert headers map to list of tuples
        Enum.map(headers, fn {key, value} -> {key, value} end)
      else
        headers
      end

    %__MODULE__{
      name: name,
      base_url: base_url,
      api_key: api_key,
      headers: headers,
      query_params: query_params
    }
  end

  # Extract query parameters from URL
  defp parse_url(url) do
    uri = URI.parse(url)

    query_params =
      if uri.query do
        uri.query
        |> URI.decode_query()
      else
        %{}
      end

    # Reconstruct base URL without query parameters
    base_url =
      %{uri | query: nil}
      |> URI.to_string()

    {base_url, query_params}
  end
end
