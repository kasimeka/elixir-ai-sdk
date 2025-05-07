defmodule AI.Core.MockLanguageModel do
  @moduledoc """
  A mock language model implementation for testing.

  This module allows you to create mock model instances with predefined behaviors
  for testing various AI.generate_text and AI.stream_text scenarios.
  """

  defstruct [
    :provider,
    :model_id,
    :supports_image_urls,
    :supports_structured_outputs,
    :supports_url,
    :do_generate,
    :do_stream
  ]

  @doc """
  Creates a new mock language model with the given options.

  ## Options
    * `:do_generate` - A function that will be called when `do_generate/1` is invoked
    * `:do_stream` - A function that will be called when `do_stream/1` is invoked
    * `:supports_image_urls` - Whether the model supports image URLs (default: false)
    * `:supports_structured_outputs` - Whether the model supports structured outputs (default: false)
    * `:supports_url` - A function that checks if a URL is supported
  """
  def new(opts \\ %{}) do
    %__MODULE__{
      provider: "mock",
      model_id: "mock-model-id",
      supports_image_urls: Map.get(opts, :supports_image_urls, false),
      supports_structured_outputs: Map.get(opts, :supports_structured_outputs, false),
      supports_url: Map.get(opts, :supports_url, fn _url -> false end),
      do_generate: Map.get(opts, :do_generate, &default_do_generate/1),
      do_stream: Map.get(opts, :do_stream, &default_do_stream/1)
    }
  end

  @doc """
  Mock implementation of the generate text function.

  By default, returns "Hello, world!" if no custom implementation is provided.
  """
  def do_generate(model, opts) do
    model.do_generate.(opts)
  end

  @doc """
  Mock implementation of the stream text function.

  By default, streams "Hello, world!" if no custom implementation is provided.
  """
  def do_stream(model, opts) do
    model.do_stream.(opts)
  end

  # Default implementations
  defp default_do_generate(_opts) do
    {:ok,
     %{
       text: "Hello, world!",
       finish_reason: "stop",
       usage: %{prompt_tokens: 10, completion_tokens: 20}
     }}
  end

  defp default_do_stream(_opts) do
    {:ok,
     %{
       stream: generate_mock_stream("Hello, world!"),
       warnings: [],
       raw_response: %{headers: %{}, body: ""}
     }}
  end

  defp generate_mock_stream(text) do
    # Creates a stream that emits the text character by character
    Stream.unfold(String.graphemes(text), fn
      [] -> nil
      [char | rest] -> {{:text_delta, char}, rest}
    end)
  end
end
