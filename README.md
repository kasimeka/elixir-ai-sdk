# Elixir AI SDK

An Elixir port of the [Vercel AI SDK](https://ai-sdk.dev/), designed to help you build AI-powered applications using Elixir and Phoenix.

## Features

- **Text Generation**: Generate text using Large Language Models (LLMs)
- **Streaming**: Stream text responses from LLMs
- **Tool Calling**: Call tools and functions from LLMs
- **Provider Support**: Support for popular AI providers (OpenAI, Anthropic, etc.)

## Installation

```elixir
def deps do
  [
    {:ai_sdk, "~> 0.1.0"}
  ]
end
```

## Usage Example

```elixir
{:ok, result} = AI.generate_text(%{
  model: AI.provider_openai("gpt-4o"),
  system: "You are a friendly assistant!",
  prompt: "Why is the sky blue?"
})

IO.puts(result.text)
```

## Architecture

The Elixir AI SDK follows similar patterns to the original Vercel AI SDK but uses Elixir idioms and patterns:

- GenServer-based streaming
- Elixir-native error handling
- Phoenix integration for web applications

## Development Status

This project is under active development. See the [project roadmap](ROADMAP.md) for more information.