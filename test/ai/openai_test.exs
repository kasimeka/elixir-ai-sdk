defmodule AI.OpenAITest do
  use ExUnit.Case, async: true
  import Mox

  alias AI.Providers.OpenAI.ChatLanguageModel

  # Ensure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "openai/2" do
    test "function is defined" do
      # Test that AI.openai exists
      assert function_exported?(AI, :openai, 2)
    end

    test "creates an OpenAI model with the required parameters" do
      model = AI.openai("gpt-4", %{})

      # Verify the model is a ChatLanguageModel struct
      assert %ChatLanguageModel{} = model

      # Verify the model ID is set correctly
      assert model.model_id == "gpt-4"

      # Verify the config is set correctly
      assert model.config.provider == "openai"
      assert is_function(model.config.headers)
      assert is_function(model.config.url)
    end

    test "handles both keyword list and map for options" do
      # Test with keyword list
      model1 = AI.openai("gpt-4", [])
      assert model1.model_id == "gpt-4"

      # Test with map
      model2 = AI.openai("gpt-4", %{})
      assert model2.model_id == "gpt-4"
    end

    test "sets API key from options correctly" do
      model = AI.openai("gpt-4", api_key: "test-api-key")

      # The api_key should be used in the headers function
      headers = model.config.headers.()
      assert headers["Authorization"] == "Bearer test-api-key"
    end

    test "sets API key from environment variable if not provided in options" do
      # Save the original environment variable value
      original_api_key = System.get_env("OPENAI_API_KEY")

      # Set the environment variable for testing
      System.put_env("OPENAI_API_KEY", "env-api-key")

      model = AI.openai("gpt-4", %{})
      headers = model.config.headers.()
      assert headers["Authorization"] == "Bearer env-api-key"

      # Restore the original environment variable
      if original_api_key do
        System.put_env("OPENAI_API_KEY", original_api_key)
      else
        System.delete_env("OPENAI_API_KEY")
      end
    end

    test "sets default base URL for API" do
      model = AI.openai("gpt-4", %{})

      # Test the URL function
      url = model.config.url.(%{path: "/chat/completions"})
      assert url == "https://api.openai.com/v1/chat/completions"
    end

    test "allows custom base URL override" do
      model = AI.openai("gpt-4", base_url: "https://custom-openai-api.com")

      # Test the URL function
      url = model.config.url.(%{path: "/chat/completions"})
      assert url == "https://custom-openai-api.com/v1/chat/completions"
    end

    test "sets additional settings correctly" do
      model =
        AI.openai("gpt-4",
          api_key: "test-api-key",
          structured_outputs: true,
          use_legacy_function_calling: true
        )

      # Check that settings are passed to the model
      assert model.settings.structured_outputs == true
      assert model.settings.use_legacy_function_calling == true
    end

    test "sets reasoning_effort for reasoning models" do
      model =
        AI.openai("o1-mini",
          api_key: "test-api-key",
          reasoning_effort: "high"
        )

      # Check that reasoning_effort is set in the model settings
      assert model.settings.reasoning_effort == "high"
    end
  end

  describe "integration with generate_text" do
    test "can use OpenAI model with generate_text" do
      # Define the mock API response
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
              "content" => "The sky appears blue because of Rayleigh scattering."
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }

      # Setup the mock to return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post} = env, _opts ->
        # Assert that the request is properly formed
        assert env.url == "https://api.openai.com/v1/chat/completions"

        # Return a successful response
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Create an OpenAI model
      model = AI.openai("gpt-4", api_key: "test-api-key")

      # Use the model with generate_text
      {:ok, result} =
        AI.generate_text(%{
          model: model,
          system: "You are a helpful assistant.",
          prompt: "Why is the sky blue?"
        })

      # Verify the result
      assert result.text == "The sky appears blue because of Rayleigh scattering."
      assert result.finish_reason == "stop"
      assert result.usage.prompt_tokens == 10
      assert result.usage.completion_tokens == 20
      assert result.usage.total_tokens == 30
    end
  end
end
