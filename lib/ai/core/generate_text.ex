defmodule AI.Core.GenerateText do
  @moduledoc """
  Core implementation for generating text using language models.

  This module handles the actual text generation functionality, including:
  - Processing the prompt and messages
  - Handling tool calls
  - Processing the model response
  """

  alias AI.Core.MockLanguageModel

  @doc """
  Generate text using a language model.

  This is the core implementation that AI.generate_text/1 calls.
  """
  def generate_text(options) do
    # Extract the model from options
    model = Map.get(options, :model)

    # Dispatch to the appropriate model's do_generate function based on type
    with {:ok, response} <- dispatch_to_model(model, options) do
      # Transform the model response into our standardized result format
      result = %{
        text: Map.get(response, :text, ""),
        reasoning: extract_reasoning(response),
        sources: Map.get(response, :sources, []),
        files: extract_files(response),
        tool_calls: Map.get(response, :tool_calls, []),
        tool_results: Map.get(response, :tool_results, []),
        finish_reason: Map.get(response, :finish_reason, "unknown"),
        usage:
          Map.get(response, :usage, %{prompt_tokens: 0, completion_tokens: 0, total_tokens: 0}),
        provider_metadata: Map.get(response, :provider_metadata, nil),
        response: response
      }

      {:ok, result}
    end
  end

  # Dispatch to the appropriate model implementation based on type
  defp dispatch_to_model(%AI.Core.MockLanguageModel{} = model, options) do
    # Use the mock model implementation
    MockLanguageModel.do_generate(model, options)
  end

  defp dispatch_to_model(%AI.Providers.OpenAICompatible.ChatLanguageModel{} = model, options) do
    # Use the OpenAI-compatible language model implementation
    alias AI.Providers.OpenAICompatible.ChatLanguageModel
    ChatLanguageModel.do_generate(model, options)
  end

  # Default catch-all for unsupported model types
  defp dispatch_to_model(model, _options) do
    {:error, "Unsupported model type: #{inspect(model)}"}
  end

  # Extract reasoning text from the response
  # This mirrors the asReasoningText function in JS
  defp extract_reasoning(%{reasoning: [%{type: "text", text: text} | _rest]}) do
    text
  end

  defp extract_reasoning(_) do
    nil
  end

  # Extract files from the response
  defp extract_files(%{files: files}) when is_list(files) do
    files
  end

  defp extract_files(_) do
    []
  end
end
