defmodule AI do
  @moduledoc """
  AI is an Elixir SDK for building AI-powered applications.

  It provides a unified API to interact with various AI model providers
  like OpenAI, Anthropic, and others.
  """

  alias AI.Core.GenerateText

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
        model: AI.provider_openai("gpt-4o"),
        system: "You are a friendly assistant!",
        prompt: "Why is the sky blue?"
      })

      IO.puts(result.text)
  """
  @spec generate_text(map()) :: {:ok, map()} | {:error, any()}
  def generate_text(options) do
    GenerateText.generate_text(options)
  end
end