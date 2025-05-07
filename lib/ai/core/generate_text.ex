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

    # Process the options to convert prompt to messages if needed
    processed_options = process_input_options(options)

    # Dispatch to the appropriate model's do_generate function based on type
    with {:ok, response} <- dispatch_to_model(model, processed_options) do
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

  # Process input options to handle prompt vs messages
  defp process_input_options(options) do
    # Handle system message
    messages = process_system_message(options)

    # Handle prompt (text string) vs messages (array)
    messages =
      case {Map.get(options, :prompt), Map.get(options, :messages)} do
        {nil, messages} when is_list(messages) ->
          # User provided :messages, use as is
          messages

        {prompt, nil} when is_binary(prompt) ->
          # User provided :prompt, convert to a user message
          messages ++ [%{role: "user", content: prompt}]

        {prompt, _messages} when is_binary(prompt) ->
          # Both :prompt and :messages were provided, prioritize :prompt
          # by converting it to a user message and appending it to existing messages
          messages ++ [%{role: "user", content: prompt}]

        {nil, nil} ->
          # Neither provided, return empty messages
          messages
      end

    # Update options with the processed messages
    options
    |> Map.put(:messages, messages)
    # Remove :prompt as we've converted it to a message
    |> Map.delete(:prompt)
  end

  # Process system message if present
  defp process_system_message(options) do
    case Map.get(options, :system) do
      nil ->
        []

      system_content when is_binary(system_content) ->
        [%{role: "system", content: system_content}]
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

  defp dispatch_to_model(%AI.Providers.OpenAI.ChatLanguageModel{} = model, options) do
    # Use the OpenAI language model implementation
    alias AI.Providers.OpenAI.ChatLanguageModel
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
