defmodule AI.Providers.OpenAICompatible.GenerateTextTest do
  use ExUnit.Case, async: true
  import Mox

  alias AI.Providers.OpenAICompatible.Provider
  alias AI.Providers.OpenAICompatible.ChatLanguageModel

  # Setup a mock provider and model for each test
  setup do
    provider =
      Provider.new(%{
        base_url: "https://api.example.com/v1",
        name: "test-provider",
        api_key: "test-api-key"
      })

    model =
      ChatLanguageModel.new(provider, %{
        model_id: "test-model"
      })

    # Ensure mocks are verified when the test exits
    verify_on_exit!()

    %{provider: provider, model: model}
  end

  describe "do_generate/2" do
    test "should extract text response from API response", %{model: model} do
      # Define the mock API response
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "test-model",
        "usage" => %{
          "prompt_tokens" => 10,
          "completion_tokens" => 20,
          "total_tokens" => 30
        },
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "This is a test response."
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }

      # Since Tesla uses middleware, we need to mock the HTTP client
      # We'll use the :hackney adapter which is used by Tesla
      expect(Tesla.MockAdapter, :call, fn %{method: :post} = env, _opts ->
        # Assert that the request is properly formed
        assert env.url == "https://api.example.com/v1/chat/completions"
        assert Jason.decode!(env.body)["model"] == "test-model"

        assert Enum.find(env.headers, fn {k, _} -> k == "Authorization" end) ==
                 {"Authorization", "Bearer test-api-key"}

        # Return a successful response
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Call the function under test with some messages
      messages = [%{role: "user", content: "Hello"}]
      opts = %{messages: messages}

      # Execute the function and get the result
      {:ok, result} = ChatLanguageModel.do_generate(model, opts)

      # Assert that the text is extracted correctly
      assert result.text == "This is a test response."
    end

    test "should extract reasoning content when available", %{model: model} do
      # Define the mock API response with reasoning content
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "test-model",
        "usage" => %{
          "prompt_tokens" => 10,
          "completion_tokens" => 20,
          "total_tokens" => 30
        },
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "Final answer",
              "reasoning" => [
                %{
                  "type" => "text",
                  "text" => "This is the reasoning content."
                }
              ]
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }

      # Setup the mock to return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post}, _opts ->
        # Return a successful response with reasoning
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Call the function with some messages
      messages = [%{role: "user", content: "Solve this problem with reasoning"}]
      opts = %{messages: messages}

      # Execute the function and get the result
      {:ok, result} = ChatLanguageModel.do_generate(model, opts)

      # Assert that both text and reasoning are extracted correctly
      assert result.text == "Final answer"
      assert result.reasoning == "This is the reasoning content."
    end

    test "should extract usage statistics", %{model: model} do
      # Define the mock API response with usage statistics
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "test-model",
        "usage" => %{
          "prompt_tokens" => 15,
          "completion_tokens" => 25,
          "total_tokens" => 40
        },
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "This is a test response."
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }

      # Setup the mock to return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post}, _opts ->
        # Return a successful response with usage statistics
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Call the function with some messages
      messages = [%{role: "user", content: "Hello with statistics"}]
      opts = %{messages: messages}

      # Execute the function and get the result
      {:ok, result} = ChatLanguageModel.do_generate(model, opts)

      # Assert that usage statistics are extracted correctly
      assert result.usage.prompt_tokens == 15
      assert result.usage.completion_tokens == 25
      assert result.usage.total_tokens == 40
    end

    test "should extract finish reason", %{model: model} do
      # Define the mock API response with a specific finish reason
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "test-model",
        "usage" => %{
          "prompt_tokens" => 10,
          "completion_tokens" => 20,
          "total_tokens" => 30
        },
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "This is a response that ends with a specific reason."
            },
            "finish_reason" => "length",
            "index" => 0
          }
        ]
      }

      # Setup the mock to return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post}, _opts ->
        # Return a successful response with a specific finish reason
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Call the function with some messages
      messages = [%{role: "user", content: "Generate a very long response"}]
      opts = %{messages: messages}

      # Execute the function and get the result
      {:ok, result} = ChatLanguageModel.do_generate(model, opts)

      # Assert that the finish reason is extracted correctly
      assert result.finish_reason == "length"
    end

    test "should handle unknown finish reason", %{model: model} do
      # Define the mock API response with a missing finish reason
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "test-model",
        "usage" => %{
          "prompt_tokens" => 10,
          "completion_tokens" => 20,
          "total_tokens" => 30
        },
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "This is a response with an unknown finish reason."
            },
            # No finish_reason field
            "index" => 0
          }
        ]
      }

      # Setup the mock to return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post}, _opts ->
        # Return a successful response with a missing finish reason
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Call the function with some messages
      messages = [%{role: "user", content: "Hello"}]
      opts = %{messages: messages}

      # Execute the function and get the result
      {:ok, result} = ChatLanguageModel.do_generate(model, opts)

      # Assert that the finish reason defaults to "unknown"
      assert result.finish_reason == "unknown"
    end

    test "should pass the model ID and messages correctly", %{model: model} do
      # Define a custom model ID and custom messages
      custom_model =
        ChatLanguageModel.new(model.provider, %{
          model_id: "custom-model-id"
        })

      # Define the expected messages
      system_message = %{role: "system", content: "You are a helpful assistant."}
      user_message = %{role: "user", content: "Tell me about Elixir."}

      # Define the mock API response
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "custom-model-id",
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "Elixir is a functional programming language..."
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }

      # Setup the mock to verify the request and return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post, body: body} = _env, _opts ->
        # Decode the request body to verify its contents
        decoded_body = Jason.decode!(body)

        # Verify the model ID is passed correctly
        assert decoded_body["model"] == "custom-model-id"

        # Verify the messages are passed correctly
        assert Enum.count(decoded_body["messages"]) == 2

        assert Enum.at(decoded_body["messages"], 0) == %{
                 "role" => "system",
                 "content" => "You are a helpful assistant."
               }

        assert Enum.at(decoded_body["messages"], 1) == %{
                 "role" => "user",
                 "content" => "Tell me about Elixir."
               }

        # Return a successful response
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Call the function with the custom messages
      messages = [system_message, user_message]
      opts = %{messages: messages}

      # Execute the function and get the result
      {:ok, result} = ChatLanguageModel.do_generate(custom_model, opts)

      # Assert the response is processed correctly
      assert result.text == "Elixir is a functional programming language..."
    end

    test "should extract tool calls from response", %{model: model} do
      # Define the mock API response with tool calls
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "test-model",
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => nil,
              "tool_calls" => [
                %{
                  "id" => "call_abc123",
                  "type" => "function",
                  "function" => %{
                    "name" => "get_weather",
                    "arguments" => "{\"location\":\"San Francisco\",\"unit\":\"celsius\"}"
                  }
                }
              ]
            },
            "finish_reason" => "tool_calls",
            "index" => 0
          }
        ]
      }

      # Setup the mock to return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post}, _opts ->
        # Return a successful response with tool calls
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Call the function with some messages
      messages = [%{role: "user", content: "What's the weather in San Francisco?"}]
      opts = %{messages: messages}

      # Execute the function and get the result
      {:ok, result} = ChatLanguageModel.do_generate(model, opts)

      # Assert that tool calls are extracted correctly
      assert Enum.count(result.tool_calls) == 1

      tool_call = Enum.at(result.tool_calls, 0)
      assert tool_call.id == "call_abc123"
      assert tool_call.type == "function"
      assert tool_call.function.name == "get_weather"
      assert tool_call.function.arguments == %{"location" => "San Francisco", "unit" => "celsius"}
    end

    test "should build appropriate request with tools and toolChoice", %{model: model} do
      # Define the tools to be used
      tools = [
        %{
          type: "function",
          function: %{
            name: "get_weather",
            description: "Get the current weather in a given location",
            parameters: %{
              type: "object",
              properties: %{
                location: %{
                  type: "string",
                  description: "The city and state, e.g. San Francisco, CA"
                },
                unit: %{
                  type: "string",
                  enum: ["celsius", "fahrenheit"],
                  description: "The unit of temperature"
                }
              },
              required: ["location"]
            }
          }
        }
      ]

      # Define the toolChoice
      tool_choice = "auto"

      # Define the mock API response
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "test-model",
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "I'll check the weather for you."
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }

      # Setup the mock to verify the request and return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post, body: body} = _env, _opts ->
        # Decode the request body to verify its contents
        decoded_body = Jason.decode!(body)

        # Verify the tools are included in the request
        # Just check the structure without an exact match (json serialization converts atoms to strings)
        assert is_list(decoded_body["tools"])
        assert length(decoded_body["tools"]) == 1

        tool = List.first(decoded_body["tools"])
        assert tool["type"] == "function"
        assert tool["function"]["name"] == "get_weather"
        assert tool["function"]["description"] == "Get the current weather in a given location"

        # Verify the toolChoice is included in the request
        assert decoded_body["tool_choice"] == tool_choice

        # Return a successful response
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Call the function with tools and toolChoice
      messages = [%{role: "user", content: "What's the weather in San Francisco?"}]

      opts = %{
        messages: messages,
        tools: tools,
        tool_choice: tool_choice
      }

      # Execute the function and get the result
      {:ok, result} = ChatLanguageModel.do_generate(model, opts)

      # Assert the response is processed correctly
      assert result.text == "I'll check the weather for you."
    end

    test "should include provider-specific options in request", %{model: model} do
      # Define provider-specific options
      temperature = 0.7
      max_tokens = 100

      response_format = %{
        type: "json_object"
      }

      # Define the mock API response
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "test-model",
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "{\"result\": \"success\"}"
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }

      # Setup the mock to verify the request and return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post, body: body} = _env, _opts ->
        # Decode the request body to verify its contents
        decoded_body = Jason.decode!(body)

        # Verify provider-specific options are included in the request
        assert decoded_body["temperature"] == temperature
        assert decoded_body["max_tokens"] == max_tokens
        assert decoded_body["response_format"]["type"] == "json_object"

        # Return a successful response
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Call the function with provider-specific options
      messages = [%{role: "user", content: "Return a JSON object with a success message"}]

      opts = %{
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens,
        response_format: response_format
      }

      # Execute the function and get the result
      {:ok, result} = ChatLanguageModel.do_generate(model, opts)

      # Assert the response is processed correctly
      assert result.text == "{\"result\": \"success\"}"
    end

    test "should send appropriate headers", %{model: _model} do
      # Create a provider with custom headers
      provider =
        Provider.new(%{
          base_url: "https://api.example.com/v1",
          name: "custom-provider",
          api_key: "test-api-key",
          headers: %{
            "X-Custom-Header" => "custom-value"
          }
        })

      # Create a model with the custom provider
      custom_model =
        ChatLanguageModel.new(provider, %{
          model_id: "custom-model"
        })

      # Define the mock API response
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "custom-model",
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "Response with custom headers"
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }

      # Setup the mock to verify the headers and return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post, headers: headers} = _env, _opts ->
        # Verify authorization header is present
        auth_header = List.keyfind(headers, "Authorization", 0)
        assert auth_header == {"Authorization", "Bearer test-api-key"}

        # Verify custom header is present
        custom_header = List.keyfind(headers, "X-Custom-Header", 0)
        assert custom_header == {"X-Custom-Header", "custom-value"}

        # Return a successful response
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Call the function with the custom model
      messages = [%{role: "user", content: "Hello with custom headers"}]
      opts = %{messages: messages}

      # Execute the function and get the result
      {:ok, result} = ChatLanguageModel.do_generate(custom_model, opts)

      # Assert the response is processed correctly
      assert result.text == "Response with custom headers"
    end

    test "should handle API errors correctly", %{model: model} do
      # Test case 1: API returns an error status code
      expect(Tesla.MockAdapter, :call, fn %{method: :post}, _opts ->
        error_response = %{
          "error" => %{
            "message" => "The model `non-existent-model` does not exist",
            "type" => "invalid_request_error",
            "param" => "model",
            "code" => "model_not_found"
          }
        }

        # Return an error response with a 404 status
        {:ok, %Tesla.Env{status: 404, body: error_response}}
      end)

      # Call the function with some messages
      messages = [%{role: "user", content: "Hello"}]
      opts = %{messages: messages}

      # Execute the function and verify the error is handled correctly
      {:error, error} = ChatLanguageModel.do_generate(model, opts)

      # Assert that the error contains the status code and error message
      assert error.status == 404
      assert error.body["error"]["message"] == "The model `non-existent-model` does not exist"

      # Test case 2: Network error
      expect(Tesla.MockAdapter, :call, fn _, _ ->
        # Simulate a network error
        {:error, :timeout}
      end)

      # Execute the function again and verify the network error is handled correctly
      {:error, error_reason} = ChatLanguageModel.do_generate(model, opts)

      # Assert that the network error is passed through
      assert error_reason == :timeout
    end
  end
end
