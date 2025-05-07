defmodule AI.Providers.OpenAICompatible.ChatLanguageModelTest do
  use ExUnit.Case, async: true

  alias AI.Providers.OpenAICompatible.Provider
  alias AI.Providers.OpenAICompatible.ChatLanguageModel

  describe "new/2" do
    test "should create a chat model with correct configuration" do
      provider =
        Provider.new(%{
          base_url: "https://api.example.com",
          name: "custom-provider",
          api_key: "test-api-key"
        })

      model =
        ChatLanguageModel.new(provider, %{
          model_id: "custom-model"
        })

      assert model.provider == provider
      assert model.model_id == "custom-model"
    end

    test "should handle provider name formatting correctly" do
      provider_with_dash =
        Provider.new(%{
          base_url: "https://api.example.com",
          name: "dash-provider",
          api_key: "test-api-key"
        })

      model_with_dash =
        ChatLanguageModel.new(provider_with_dash, %{
          model_id: "model-name"
        })

      assert model_with_dash.provider.name == "dash-provider"
      assert model_with_dash.formatted_provider == "dash-provider"

      provider_with_underscore =
        Provider.new(%{
          base_url: "https://api.example.com",
          name: "underscore_provider",
          api_key: "test-api-key"
        })

      model_with_underscore =
        ChatLanguageModel.new(provider_with_underscore, %{
          model_id: "model_name"
        })

      assert model_with_underscore.provider.name == "underscore_provider"
      assert model_with_underscore.formatted_provider == "underscore_provider"
    end
  end
end
