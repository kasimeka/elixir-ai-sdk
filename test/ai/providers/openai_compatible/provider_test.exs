defmodule AI.Providers.OpenAICompatible.ProviderTest do
  use ExUnit.Case, async: true

  alias AI.Providers.OpenAICompatible.Provider

  describe "new/1" do
    test "should create provider with correct configuration" do
      provider =
        Provider.new(%{
          base_url: "https://api.example.com",
          name: "custom-provider",
          api_key: "test-api-key",
          headers: %{"Custom-Header" => "value"}
        })

      assert provider.base_url == "https://api.example.com"
      assert provider.name == "custom-provider"
      assert provider.api_key == "test-api-key"
      # Find header in the list of tuples
      custom_header = List.keyfind(provider.headers, "Custom-Header", 0)
      auth_header = List.keyfind(provider.headers, "Authorization", 0)

      assert custom_header == {"Custom-Header", "value"}
      assert auth_header == {"Authorization", "Bearer test-api-key"}
    end

    test "should create headers without Authorization when no apiKey provided" do
      provider =
        Provider.new(%{
          base_url: "https://api.example.com",
          name: "custom-provider",
          headers: %{"Custom-Header" => "value"}
        })

      assert provider.base_url == "https://api.example.com"
      assert provider.name == "custom-provider"
      assert provider.api_key == nil
      # Find header in the list of tuples
      custom_header = List.keyfind(provider.headers, "Custom-Header", 0)
      auth_header = List.keyfind(provider.headers, "Authorization", 0)

      assert custom_header == {"Custom-Header", "value"}
      assert auth_header == nil
    end

    test "should remove trailing slash from baseURL" do
      provider =
        Provider.new(%{
          base_url: "https://api.example.com/",
          name: "custom-provider"
        })

      assert provider.base_url == "https://api.example.com"
    end

    test "should handle url with query parameters" do
      provider =
        Provider.new(%{
          base_url: "https://api.example.com?param=value",
          name: "custom-provider"
        })

      assert provider.base_url == "https://api.example.com"
      assert provider.query_params == %{"param" => "value"}
    end

    test "should require baseURL parameter" do
      assert_raise ArgumentError, fn ->
        Provider.new(%{name: "custom-provider"})
      end
    end
  end
end
