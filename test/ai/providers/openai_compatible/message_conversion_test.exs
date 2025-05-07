defmodule AI.Providers.OpenAICompatible.MessageConversionTest do
  use ExUnit.Case, async: true

  alias AI.Providers.OpenAICompatible.MessageConversion

  describe "convert_to_openai_compatible_chat_messages/1" do
    test "should convert messages with only text parts to string content" do
      messages = [
        %{role: "user", content: "Hello, world!"}
      ]

      converted = MessageConversion.convert_to_openai_compatible_chat_messages(messages)

      assert length(converted) == 1
      [first_message] = converted
      assert first_message.role == "user"
      assert first_message.content == "Hello, world!"
    end

    test "should convert user messages with proper roles" do
      messages = [
        %{role: "user", content: "Hello!"},
        %{role: "assistant", content: "Hi there!"},
        %{role: "user", content: "How are you?"}
      ]

      converted = MessageConversion.convert_to_openai_compatible_chat_messages(messages)

      assert length(converted) == 3
      [first, second, third] = converted

      assert first.role == "user"
      assert first.content == "Hello!"

      assert second.role == "assistant"
      assert second.content == "Hi there!"

      assert third.role == "user"
      assert third.content == "How are you?"
    end

    test "should convert system messages correctly" do
      messages = [
        %{role: "system", content: "You are a helpful assistant."},
        %{role: "user", content: "Hello!"}
      ]

      converted = MessageConversion.convert_to_openai_compatible_chat_messages(messages)

      assert length(converted) == 2
      [system, user] = converted

      assert system.role == "system"
      assert system.content == "You are a helpful assistant."

      assert user.role == "user"
      assert user.content == "Hello!"
    end

    test "should stringify arguments to tool calls" do
      messages = [
        %{
          role: "assistant",
          content: nil,
          tool_calls: [
            %{
              id: "call_123",
              type: "function",
              function: %{
                name: "get_weather",
                arguments: %{
                  location: "San Francisco",
                  unit: "celsius"
                }
              }
            }
          ]
        }
      ]

      converted = MessageConversion.convert_to_openai_compatible_chat_messages(messages)

      assert length(converted) == 1
      [assistant] = converted

      assert assistant.role == "assistant"
      assert assistant.content == nil
      assert length(assistant.tool_calls) == 1

      [tool_call] = assistant.tool_calls
      assert tool_call.id == "call_123"
      assert tool_call.type == "function"
      assert tool_call.function.name == "get_weather"
      # Arguments should be stringified
      assert is_binary(tool_call.function.arguments)
      assert String.contains?(tool_call.function.arguments, "San Francisco")
      assert String.contains?(tool_call.function.arguments, "celsius")
    end

    test "should convert tool result messages correctly" do
      messages = [
        %{
          role: "tool",
          content: "The weather in San Francisco is 18°C and partly cloudy.",
          tool_call_id: "call_123"
        }
      ]

      converted = MessageConversion.convert_to_openai_compatible_chat_messages(messages)

      assert length(converted) == 1
      [tool_result] = converted

      assert tool_result.role == "tool"
      assert tool_result.content == "The weather in San Francisco is 18°C and partly cloudy."
      assert tool_result.tool_call_id == "call_123"
    end
  end
end
