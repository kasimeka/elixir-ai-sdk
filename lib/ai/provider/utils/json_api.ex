defmodule AI.Provider.Utils.JsonApi do
  @moduledoc """
  Utility functions for making JSON API requests.
  """

  @type response :: {:ok, map()} | {:error, term()}

  @spec post(String.t(), map(), map(), map()) :: response()
  def post(_url, _body, _headers, _options) do
    # TODO: Implement actual HTTP request
    {:ok, %{status: 200, body: %{choices: [%{message: %{content: "Hello, world!"}}]}}}
  end
end 