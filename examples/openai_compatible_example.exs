# Sample script demonstrating AI.generate_text usage with an openai-compatible api
# Run from the elixir-ai-sdk root directory with: 
# mix run examples/openai_compatible_example.exs

# Make sure you've set the GOOGLE_API_KEY environment variable

defmodule OpenAICompatibleExample do
  def run do
    IO.puts("Starting generate_text example...\n")

    api_key = System.get_env("GOOGLE_API_KEY")

    if is_nil(api_key) do
      IO.puts("Error: GOOGLE_API_KEY environment variable not set")
      System.halt(1)
    end

    {:ok, result} =
      AI.generate_text(%{
        prompt: "is elixir a statically typed programming language?",
        model:
          AI.openai_compatible(
            "gemini-2.5-flash",
            base_url: "https://generativelanguage.googleapis.com/v1beta/openai",
            api_key: api_key
          )
      })

    IO.puts(result.text)
  end
end

# Run the example
OpenAICompatibleExample.run()
