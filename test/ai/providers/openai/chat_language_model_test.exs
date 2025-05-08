defmodule AI.Providers.OpenAI.ChatLanguageModelTest do
  use ExUnit.Case, async: true
  import Mox

  alias AI.Providers.OpenAI.ChatLanguageModel

  # Ensure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "model creation and configuration" do
    setup do
      model =
        ChatLanguageModel.new(
          "gpt-4",
          %{},
          %{
            provider: "openai",
            headers: fn -> %{"Authorization" => "Bearer test"} end,
            url: fn %{path: path} -> "https://api.openai.com/v1#{path}" end
          }
        )

      %{model: model}
    end

    test "creates a model with correct configuration", %{model: model} do
      assert model.model_id == "gpt-4"
      assert model.settings == %{}
      assert model.config.provider == "openai"
    end

    test "retrieves specification version" do
      assert ChatLanguageModel.specification_version() == "v1"
    end

    test "supports structured outputs", %{model: model} do
      assert ChatLanguageModel.supports_structured_outputs?(model) == false
    end

    test "default object generation mode", %{model: model} do
      assert ChatLanguageModel.default_object_generation_mode(model) == :tool
    end

    test "retrieves provider information", %{model: model} do
      assert ChatLanguageModel.provider(model) == "openai"
    end

    test "supports image URLs", %{model: model} do
      assert ChatLanguageModel.supports_image_urls?(model) == true
    end
  end

  describe "generation" do
    setup do
      model =
        ChatLanguageModel.new(
          "gpt-4",
          %{},
          %{
            provider: "openai",
            headers: fn -> %{"Authorization" => "Bearer test"} end,
            url: fn %{path: path} -> "https://api.openai.com/v1#{path}" end
          }
        )

      %{model: model}
    end

    test "handles successful generation", %{model: model} do
      # Define a mock response to return
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "gpt-4",
        "usage" => %{
          "prompt_tokens" => 10,
          "completion_tokens" => 20,
          "total_tokens" => 30
        },
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "Hello, world!"
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }

      # Setup the mock adapter to return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post} = env, _opts ->
        # Assert that we're making the right request
        assert env.url == "https://api.openai.com/v1/chat/completions"

        # Return a successful response
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Set up the options
      options = %{
        mode: %{type: :regular},
        prompt: [{:user, [%{type: :text, text: "Hello, world!"}]}],
        max_tokens: 100,
        temperature: 0.7,
        top_p: 1.0,
        top_k: nil,
        frequency_penalty: 0.0,
        presence_penalty: 0.0,
        stop_sequences: nil,
        response_format: nil,
        seed: nil,
        provider_metadata: %{}
      }

      # Make the request
      assert {:ok, result} = ChatLanguageModel.do_generate(model, options)

      # Verify the result
      assert result.text == "Hello, world!"
      assert result.finish_reason == "stop"
      assert result.usage == %{prompt_tokens: 10, completion_tokens: 20, total_tokens: 30}
    end

    test "handles error response", %{model: _model} do
      # TODO: Implement error handling test
    end
  end

  describe "streaming" do
    setup do
      model =
        ChatLanguageModel.new(
          "gpt-4",
          %{},
          %{
            provider: "openai",
            headers: fn -> %{"Authorization" => "Bearer test"} end,
            url: fn %{path: path} -> "https://api.openai.com/v1#{path}" end
          }
        )

      %{model: model}
    end

    test "handles simulated streaming", %{model: model} do
      # Set simulate_streaming to true
      model = %{model | settings: %{simulate_streaming: true}}

      # Define a mock response to return
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "gpt-4",
        "usage" => %{
          "prompt_tokens" => 10,
          "completion_tokens" => 20,
          "total_tokens" => 30
        },
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "Hello, world!"
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }

      # Setup the mock adapter to return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post} = env, _opts ->
        # Assert that we're making the right request
        assert env.url == "https://api.openai.com/v1/chat/completions"

        # Return a successful response
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Set up the options
      options = %{
        mode: %{type: :regular},
        prompt: [{:user, [%{type: :text, text: "Hello, world!"}]}],
        max_tokens: 100,
        temperature: 0.7,
        top_p: 1.0,
        top_k: nil,
        frequency_penalty: 0.0,
        presence_penalty: 0.0,
        stop_sequences: nil,
        response_format: nil,
        seed: nil,
        provider_metadata: %{}
      }

      assert {:ok, result} = ChatLanguageModel.do_stream(model, options)
      assert is_map(result.stream)
      assert result.raw_call != nil
      assert result.warnings == []
    end

    @tag :skip
    test "handles real streaming", %{model: model} do
      # This is marked as skip as it uses EventSource which is not yet fully implemented

      # We're skipping this test, so we don't need to set up options
      # Just documenting what the options would look like when implemented
      _options = %{
        mode: %{type: :regular},
        prompt: [{:user, [%{type: :text, text: "Hello, world!"}]}],
        max_tokens: 100,
        temperature: 0.7,
        top_p: 1.0,
        top_k: nil,
        frequency_penalty: 0.0,
        presence_penalty: 0.0,
        stop_sequences: nil,
        response_format: nil,
        seed: nil,
        provider_metadata: %{}
      }

      # TODO: Implement proper EventSource mocking when we implement real streaming

      # Just a temporary check while this test is skipped
      assert is_map(model)
    end

    test "handles streaming error", %{model: _model} do
      # TODO: Implement error handling test
    end
  end
end
