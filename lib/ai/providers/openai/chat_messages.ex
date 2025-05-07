defmodule AI.Providers.OpenAI.ChatMessages do
  @moduledoc """
  Converts messages to OpenAI chat format, handling various message types,
  roles, and content formats.
  """

  @type system_message_mode :: :system | :developer | :remove
  @type warning :: %{type: :other, message: String.t()}
  @type message :: %{
    role: String.t(),
    content: String.t() | list(map()),
    function_call: map() | nil,
    tool_calls: list(map()) | nil
  }

  @doc """
  Converts messages to OpenAI chat format.

  ## Options
    * `:use_legacy_function_calling` - Whether to use legacy function calling format (default: false)
    * `:system_message_mode` - How to handle system messages (:system, :developer, or :remove)
  """
  def convert_to_openai_chat_messages(prompt, opts \\ []) do
    use_legacy_function_calling = Keyword.get(opts, :use_legacy_function_calling, false)
    system_message_mode = Keyword.get(opts, :system_message_mode, :system)

    {messages, warnings} =
      Enum.reduce(prompt, {[], []}, fn {role, content}, {acc_messages, acc_warnings} ->
        {new_messages, new_warnings} = process_message(role, content, use_legacy_function_calling, system_message_mode)
        {acc_messages ++ new_messages, acc_warnings ++ new_warnings}
      end)

    %{messages: messages, warnings: warnings}
  end

  defp process_message(:system, content, _use_legacy_function_calling, system_message_mode) do
    case system_message_mode do
      :system ->
        {[%{role: "system", content: content}], []}

      :developer ->
        {[%{role: "developer", content: content}], []}

      :remove ->
        {[], [%{type: :other, message: "system messages are removed for this model"}]}

      _ ->
        raise "Unsupported system message mode: #{system_message_mode}"
    end
  end

  defp process_message(:user, content, _use_legacy_function_calling, _system_message_mode) do
    if length(content) == 1 && hd(content).type == :text do
      {[%{role: "user", content: hd(content).text}], []}
    else
      converted_content =
        Enum.map(content, fn part ->
          case part.type do
            :text ->
              %{type: "text", text: part.text}

            :image ->
              url =
                case part.image do
                  %URI{} -> URI.to_string(part.image)
                  _ ->
                    mime_type = part.mime_type || "image/jpeg"
                    "data:#{mime_type};base64,#{Base.encode64(part.image)}"
                end

              %{
                type: "image_url",
                image_url: %{
                  url: url,
                  detail: get_in(part, [:provider_metadata, :openai, :image_detail])
                }
              }

            :file ->
              case part.data do
                %URI{} ->
                  raise "File content parts with URL data functionality not supported"

                _ ->
                  case part.mime_type do
                    "audio/wav" ->
                      %{
                        type: "input_audio",
                        input_audio: %{data: part.data, format: "wav"}
                      }

                    "audio/mp3" ->
                      %{
                        type: "input_audio",
                        input_audio: %{data: part.data, format: "mp3"}
                      }

                    "audio/mpeg" ->
                      %{
                        type: "input_audio",
                        input_audio: %{data: part.data, format: "mp3"}
                      }

                    "application/pdf" ->
                      %{
                        type: "file",
                        file: %{
                          filename: part.filename || "part.pdf",
                          file_data: "data:application/pdf;base64,#{part.data}"
                        }
                      }

                    _ ->
                      raise "File content part type #{part.mime_type} in user messages"
                  end
              end
          end
        end)

      {[%{role: "user", content: converted_content}], []}
    end
  end

  defp process_message(:assistant, content, use_legacy_function_calling, _system_message_mode) do
    {text, tool_calls} =
      Enum.reduce(content, {"", []}, fn part, {acc_text, acc_tool_calls} ->
        case part.type do
          :text ->
            {acc_text <> part.text, acc_tool_calls}

          :tool_call ->
            tool_call = %{
              id: part.tool_call_id,
              type: "function",
              function: %{
                name: part.tool_name,
                arguments: Jason.encode!(part.args)
              }
            }
            {acc_text, acc_tool_calls ++ [tool_call]}
        end
      end)

    if use_legacy_function_calling do
      if length(tool_calls) > 1 do
        raise "use_legacy_function_calling with multiple tool calls in one message"
      end

      message = %{
        role: "assistant",
        content: text
      }

      message =
        if tool_calls == [] do
          message
        else
          Map.put(message, :function_call, hd(tool_calls).function)
        end

      {[message], []}
    else
      message = %{
        role: "assistant",
        content: text
      }

      message =
        if tool_calls == [] do
          message
        else
          Map.put(message, :tool_calls, tool_calls)
        end

      {[message], []}
    end
  end

  defp process_message(:tool, content, use_legacy_function_calling, _system_message_mode) do
    messages =
      Enum.map(content, fn tool_response ->
        if use_legacy_function_calling do
          %{
            role: "function",
            name: tool_response.tool_name,
            content: Jason.encode!(tool_response.result)
          }
        else
          %{
            role: "tool",
            tool_call_id: tool_response.tool_call_id,
            content: Jason.encode!(tool_response.result)
          }
        end
      end)

    {messages, []}
  end

  defp process_message(role, _content, _use_legacy_function_calling, _system_message_mode) do
    raise "Unsupported role: #{role}"
  end
end 