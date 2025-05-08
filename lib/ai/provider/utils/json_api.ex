defmodule AI.Provider.Utils.JsonApi do
  @moduledoc """
  Utility functions for making JSON API requests.
  """

  @type response :: {:ok, map()} | {:error, term()}

  @doc """
  Makes a POST request to a JSON API endpoint.

  ## Parameters
    * `url` - The URL to send the request to
    * `body` - The request body (will be converted to JSON)
    * `headers` - Map of HTTP headers
    * `options` - Additional options

  ## Returns
    * `{:ok, response}` - The successful response
    * `{:error, reason}` - The error reason
  """
  @spec post(String.t(), map(), map(), map()) :: response()
  def post(url, body, headers, _options) do
    # Create a Tesla client with JSON middleware
    headers_list = Enum.map(headers, fn {key, value} -> {to_string(key), to_string(value)} end)

    client =
      Tesla.client([
        {Tesla.Middleware.Headers, headers_list},
        {Tesla.Middleware.JSON, []}
      ])

    # Make the request
    case Tesla.post(client, url, body) do
      {:ok, %Tesla.Env{status: status, body: response_body}}
      when status >= 200 and status < 300 ->
        {:ok, response_body}

      {:ok, %Tesla.Env{status: status, body: response_body}} ->
        {:error, %{status: status, body: response_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
