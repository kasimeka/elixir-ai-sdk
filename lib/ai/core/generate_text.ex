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
    # For now we just pass through to the model's do_generate function
    # This will be extended with all the features as we implement them
    
    model = Map.get(options, :model)
    
    with {:ok, response} <- MockLanguageModel.do_generate(model, options) do
      # Transform the model response into our standardized result format
      result = %{
        text: Map.get(response, :text, ""),
        reasoning: extract_reasoning(response),
        sources: Map.get(response, :sources, []),
        files: extract_files(response),
        tool_calls: Map.get(response, :tool_calls, []),
        tool_results: Map.get(response, :tool_results, []),
        finish_reason: Map.get(response, :finish_reason, "unknown"),
        usage: Map.get(response, :usage, %{prompt_tokens: 0, completion_tokens: 0, total_tokens: 0}),
        provider_metadata: Map.get(response, :provider_metadata, nil),
        response: response
      }
      
      {:ok, result}
    end
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