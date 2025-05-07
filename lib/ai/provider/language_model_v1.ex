defmodule AI.Provider.LanguageModelV1 do
  @moduledoc """
  Behaviour for language model providers.
  """

  @callback specification_version() :: String.t()
  @callback supports_structured_outputs?(term()) :: boolean()
  @callback default_object_generation_mode(term()) :: :json | :tool
  @callback provider(term()) :: String.t()
  @callback supports_image_urls?(term()) :: boolean()
  @callback do_generate(term(), map()) :: {:ok, map()} | {:error, term()}
  @callback do_stream(term(), map()) :: {:ok, map()} | {:error, term()}
end
