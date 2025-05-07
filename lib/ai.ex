defmodule AI do
  @moduledoc """
  AI is an Elixir SDK for building AI-powered applications.

  It provides a unified API to interact with various AI model providers
  like OpenAI, Anthropic, and others.
  """

  alias AI.Core.GenerateText
  alias AI.Providers.OpenAICompatible.Provider
  alias AI.Providers.OpenAICompatible.ChatLanguageModel

  @doc """
  Generates text using an AI model.

  ## Options

    * `:model` - The language model to use
    * `:system` - A system message that will be part of the prompt
    * `:prompt` - A simple text prompt (can use either prompt or messages)
    * `:messages` - A list of messages (can use either prompt or messages)
    * `:max_tokens` - Maximum number of tokens to generate
    * `:temperature` - Temperature setting for randomness
    * `:top_p` - Nucleus sampling
    * `:tools` - Tools that are accessible to and can be called by the model
    * `:tool_choice` - The tool choice strategy (default: 'auto')

  ## Examples

      {:ok, result} = AI.generate_text(%{
        model: AI.openai_compatible("gpt-3.5-turbo", base_url: "https://api.example.com"),
        system: "You are a friendly assistant!",
        prompt: "Why is the sky blue?"
      })

      IO.puts(result.text)
  """
  @spec generate_text(map()) :: {:ok, map()} | {:error, any()}
  def generate_text(options) do
    GenerateText.generate_text(options)
  end

  @doc """
  Creates an OpenAI-compatible provider with the specified model ID.

  This function creates a model that can be used with OpenAI-compatible APIs,
  such as Ollama, LMStudio, and any other API that follows the OpenAI format.

  ## Options
    * `:base_url` - The base URL of the API (required)
    * `:api_key` - The API key to use for authentication (optional)
    * `:headers` - Additional headers to include in requests (optional)
    * `:supports_image_urls` - Whether the model supports image URLs (default: false)
    * `:supports_structured_outputs` - Whether the model supports structured outputs (default: false)

  ## Examples

      model = AI.openai_compatible("gpt-3.5-turbo", base_url: "https://api.example.com")
      
      # With API key
      model = AI.openai_compatible("gpt-4", 
        base_url: "https://api.openai.com", 
        api_key: System.get_env("OPENAI_API_KEY")
      )
  """
  @spec openai_compatible(String.t(), keyword() | map()) :: struct()
  def openai_compatible(model_id, opts \\ %{}) do
    # Convert keyword list to map if needed
    opts = if Keyword.keyword?(opts), do: Map.new(opts), else: opts

    # Create the provider
    provider = Provider.new(opts)

    # Create the chat language model
    ChatLanguageModel.new(provider, Map.put(opts, :model_id, model_id))
  end
end
