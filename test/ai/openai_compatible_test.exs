defmodule AI.OpenAICompatibleTest do
  use ExUnit.Case, async: true
  import Mox

  alias AI.Providers.OpenAICompatible.Provider
  alias AI.Providers.OpenAICompatible.ChatLanguageModel

  # Ensure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "openai_compatible/2" do
    test "function is defined" do
      # Test that AI.openai_compatible exists
      assert function_exported?(AI, :openai_compatible, 2)
    end

    test "creates an OpenAI-compatible model with the required parameters" do
      model = AI.openai_compatible("gpt-3.5-turbo", base_url: "https://api.example.com")

      # Verify the model is a ChatLanguageModel struct
      assert %ChatLanguageModel{} = model

      # Verify the model ID is set correctly
      assert model.model_id == "gpt-3.5-turbo"

      # Verify the provider is set correctly
      assert %Provider{} = model.provider
      assert model.provider.base_url == "https://api.example.com"
    end

    test "handles both keyword list and map for options" do
      # Test with keyword list
      model1 = AI.openai_compatible("gpt-3.5-turbo", base_url: "https://api.example.com")
      assert model1.provider.base_url == "https://api.example.com"

      # Test with map
      model2 = AI.openai_compatible("gpt-3.5-turbo", %{base_url: "https://api.other.com"})
      assert model2.provider.base_url == "https://api.other.com"
    end

    test "sets additional options correctly" do
      model =
        AI.openai_compatible("gpt-3.5-turbo",
          base_url: "https://api.example.com",
          api_key: "test-api-key",
          headers: %{"X-Custom-Header" => "test-value"},
          supports_image_urls: true,
          supports_structured_outputs: true
        )

      # Verify all options are passed correctly
      assert model.provider.api_key == "test-api-key"
      assert {"X-Custom-Header", "test-value"} in model.provider.headers
      assert model.supports_image_urls == true
      assert model.supports_structured_outputs == true
    end
  end

  describe "integration with generate_text" do
    test "can use OpenAI-compatible model with generate_text" do
      # Define the mock API response
      mock_response = %{
        "id" => "chatcmpl-abc123",
        "object" => "chat.completion",
        "created" => 1_677_858_242,
        "model" => "gpt-3.5-turbo",
        "usage" => %{
          "prompt_tokens" => 10,
          "completion_tokens" => 20,
          "total_tokens" => 30
        },
        "choices" => [
          %{
            "message" => %{
              "role" => "assistant",
              "content" => "The sky is blue because of Rayleigh scattering."
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }

      # Setup the mock to return our response
      expect(Tesla.MockAdapter, :call, fn %{method: :post} = env, _opts ->
        # Assert that the request is properly formed
        assert env.url == "https://api.example.com/v1/chat/completions"

        # Return a successful response
        {:ok, %Tesla.Env{status: 200, body: mock_response}}
      end)

      # Create an OpenAI-compatible model
      model = AI.openai_compatible("gpt-3.5-turbo", base_url: "https://api.example.com")

      # Use the model with generate_text
      {:ok, result} =
        AI.generate_text(%{
          model: model,
          system: "You are a helpful assistant.",
          prompt: "Why is the sky blue?"
        })

      # Verify the result
      assert result.text == "The sky is blue because of Rayleigh scattering."
      assert result.finish_reason == "stop"
      assert result.usage.prompt_tokens == 10
      assert result.usage.completion_tokens == 20
      assert result.usage.total_tokens == 30
    end
  end
end
