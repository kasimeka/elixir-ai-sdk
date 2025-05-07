defmodule AI.Providers.OpenAICompatible.MessageConversion do
  @moduledoc """
  Utilities for converting between AI.Core message formats and OpenAI API formats.
  """

  @doc """
  Converts AI.Core messages to OpenAI-compatible chat messages format.
  """
  def convert_to_openai_compatible_chat_messages(messages) do
    Enum.map(messages, &convert_message/1)
  end

  # Convert a tool result message
  defp convert_message(%{role: "tool", content: content, tool_call_id: tool_call_id}) do
    %{
      role: "tool",
      content: content,
      tool_call_id: tool_call_id
    }
  end

  # Convert a message with tool calls
  defp convert_message(%{role: role, content: content, tool_calls: tool_calls})
       when is_list(tool_calls) do
    %{
      role: role,
      content: content,
      tool_calls: Enum.map(tool_calls, &convert_tool_call/1)
    }
  end

  # Convert a message with text content
  defp convert_message(%{role: role, content: content}) when is_binary(content) do
    %{role: role, content: content}
  end

  # Convert a tool call
  defp convert_tool_call(%{id: id, type: type, function: function}) do
    # Extract and stringify function arguments
    arguments =
      case function do
        %{name: _name, arguments: args} when is_map(args) ->
          # Convert arguments map to JSON string
          Jason.encode!(args)

        %{name: _name, arguments: args} when is_binary(args) ->
          # Already a string
          args

        _ ->
          "{}"
      end

    # Return the converted tool call
    %{
      id: id,
      type: type,
      function: %{
        name: function.name,
        arguments: arguments
      }
    }
  end
end
