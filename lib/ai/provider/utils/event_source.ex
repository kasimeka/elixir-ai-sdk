defmodule AI.Provider.Utils.EventSource do
  @moduledoc """
  Utility functions for handling Server-Sent Events (SSE).
  """

  @type response :: {:ok, map()} | {:error, term()}

  @spec post(String.t(), map(), map(), map()) :: response()
  def post(_url, _body, _headers, _options) do
    # TODO: Implement actual SSE request
    {:ok, %{status: 200, body: "data: {\"choices\":[{\"delta\":{\"content\":\"Hello, world!\"}}]}\n\n"}}
  end
end 