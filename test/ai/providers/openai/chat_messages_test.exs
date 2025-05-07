defmodule AI.Providers.OpenAI.ChatMessagesTest do
  use ExUnit.Case, async: true
  alias AI.Providers.OpenAI.ChatMessages

  describe "system messages" do
    test "should forward system messages" do
      result = ChatMessages.convert_to_openai_chat_messages([
        {:system, "You are a helpful assistant."}
      ])

      assert result.messages == [
        %{role: "system", content: "You are a helpful assistant."}
      ]
    end

    test "should convert system messages to developer messages when requested" do
      result = ChatMessages.convert_to_openai_chat_messages(
        [{:system, "You are a helpful assistant."}],
        system_message_mode: :developer
      )

      assert result.messages == [
        %{role: "developer", content: "You are a helpful assistant."}
      ]
    end

    test "should remove system messages when requested" do
      result = ChatMessages.convert_to_openai_chat_messages(
        [{:system, "You are a helpful assistant."}],
        system_message_mode: :remove
      )

      assert result.messages == []
      assert result.warnings == [
        %{type: :other, message: "system messages are removed for this model"}
      ]
    end
  end

  describe "user messages" do
    test "should convert messages with only a text part to a string content" do
      result = ChatMessages.convert_to_openai_chat_messages([
        {:user, [%{type: :text, text: "Hello"}]}
      ])

      assert result.messages == [
        %{role: "user", content: "Hello"}
      ]
    end

    test "should convert messages with image parts" do
      result = ChatMessages.convert_to_openai_chat_messages([
        {:user, [
          %{type: :text, text: "Hello"},
          %{type: :image, image: <<0, 1, 2, 3>>, mime_type: "image/png"}
        ]}
      ])

      assert result.messages == [
        %{
          role: "user",
          content: [
            %{type: "text", text: "Hello"},
            %{
              type: "image_url",
              image_url: %{
                url: "data:image/png;base64,AAECAw==",
                detail: nil
              }
            }
          ]
        }
      ]
    end

    test "should add image detail when specified through extension" do
      result = ChatMessages.convert_to_openai_chat_messages([
        {:user, [
          %{
            type: :image,
            image: <<0, 1, 2, 3>>,
            mime_type: "image/png",
            provider_metadata: %{
              openai: %{
                image_detail: "low"
              }
            }
          }
        ]}
      ])

      assert result.messages == [
        %{
          role: "user",
          content: [
            %{
              type: "image_url",
              image_url: %{
                url: "data:image/png;base64,AAECAw==",
                detail: "low"
              }
            }
          ]
        }
      ]
    end
  end

  describe "file parts" do
    test "should throw for unsupported mime types" do
      assert_raise RuntimeError, "File content part type image/png in user messages", fn ->
        ChatMessages.convert_to_openai_chat_messages([
          {:user, [
            %{
              type: :file,
              data: "AAECAw==",
              mime_type: "image/png"
            }
          ]}
        ])
      end
    end

    test "should throw for URL data" do
      assert_raise RuntimeError, "File content parts with URL data functionality not supported", fn ->
        ChatMessages.convert_to_openai_chat_messages([
          {:user, [
            %{
              type: :file,
              data: URI.parse("https://example.com/foo.wav"),
              mime_type: "audio/wav"
            }
          ]}
        ])
      end
    end

    test "should add audio content for audio/wav file parts" do
      result = ChatMessages.convert_to_openai_chat_messages([
        {:user, [
          %{
            type: :file,
            data: "AAECAw==",
            mime_type: "audio/wav"
          }
        ]}
      ])

      assert result.messages == [
        %{
          role: "user",
          content: [
            %{
              type: "input_audio",
              input_audio: %{
                data: "AAECAw==",
                format: "wav"
              }
            }
          ]
        }
      ]
    end

    test "should convert messages with PDF file parts" do
      result = ChatMessages.convert_to_openai_chat_messages([
        {:user, [
          %{
            type: :file,
            mime_type: "application/pdf",
            data: "AQIDBAU=",
            filename: "document.pdf"
          }
        ]}
      ])

      assert result.messages == [
        %{
          role: "user",
          content: [
            %{
              type: "file",
              file: %{
                filename: "document.pdf",
                file_data: "data:application/pdf;base64,AQIDBAU="
              }
            }
          ]
        }
      ]
    end
  end

  describe "tool calls" do
    test "should stringify arguments to tool calls" do
      result = ChatMessages.convert_to_openai_chat_messages([
        {:assistant, [
          %{
            type: :tool_call,
            args: %{foo: "bar123"},
            tool_call_id: "quux",
            tool_name: "thwomp"
          }
        ]},
        {:tool, [
          %{
            type: :tool_result,
            tool_call_id: "quux",
            tool_name: "thwomp",
            result: %{oof: "321rab"}
          }
        ]}
      ])

      assert result.messages == [
        %{
          role: "assistant",
          content: "",
          tool_calls: [
            %{
              type: "function",
              id: "quux",
              function: %{
                name: "thwomp",
                arguments: Jason.encode!(%{foo: "bar123"})
              }
            }
          ]
        },
        %{
          role: "tool",
          content: Jason.encode!(%{oof: "321rab"}),
          tool_call_id: "quux"
        }
      ]
    end

    test "should convert tool calls to function calls with use_legacy_function_calling" do
      result = ChatMessages.convert_to_openai_chat_messages(
        [
          {:assistant, [
            %{
              type: :tool_call,
              args: %{foo: "bar123"},
              tool_call_id: "quux",
              tool_name: "thwomp"
            }
          ]},
          {:tool, [
            %{
              type: :tool_result,
              tool_call_id: "quux",
              tool_name: "thwomp",
              result: %{oof: "321rab"}
            }
          ]}
        ],
        use_legacy_function_calling: true
      )

      assert result.messages == [
        %{
          role: "assistant",
          content: "",
          function_call: %{
            name: "thwomp",
            arguments: Jason.encode!(%{foo: "bar123"})
          }
        },
        %{
          role: "function",
          content: Jason.encode!(%{oof: "321rab"}),
          name: "thwomp"
        }
      ]
    end
  end
end 