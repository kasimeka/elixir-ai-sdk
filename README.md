# Elixir AI SDK

An Elixir port of the [Vercel AI SDK](https://ai-sdk.dev/), designed to help you build AI-powered applications using Elixir and Phoenix.

## Features

- **Text Generation**: Generate text using Large Language Models (LLMs)
- **Real-time Streaming**: Stream text responses chunk-by-chunk as they're generated
- **Server-Sent Events (SSE)**: Efficient streaming with proper backpressure handling
- **Tool Calling**: Call tools and functions from LLMs
- **Provider Support**: Support for popular AI providers (OpenAI, Anthropic, etc.)
- **Elixir Integration**: Seamless integration with Elixir's Stream API

## Installation

```elixir
def deps do
  [
    {:ai_sdk, "~> 0.0.1-rc.0"}
  ]
end
```

## Usage Examples

### Text Generation

```elixir
{:ok, result} = AI.generate_text(%{
  model: AI.openai("gpt-4o"),
  system: "You are a friendly assistant!",
  prompt: "Why is the sky blue?"
})

IO.puts(result.text)
```

### Streaming Text Generation

```elixir
# Default mode: returns a stream of text strings
{:ok, result} = AI.stream_text(%{
  model: AI.openai("gpt-4o"),
  system: "You are a friendly assistant!",
  prompt: "Why is the sky blue?"
})

# Simple string processing
result.stream
|> Stream.each(&IO.write/1)
|> Stream.run()

# Or collect all chunks
full_text = Enum.join(result.stream, "")
```

### Advanced Streaming with Event Mode

```elixir
# Event mode: returns a stream of event tuples for fine-grained control
{:ok, result} = AI.stream_text(%{
  model: AI.openai("gpt-4o"),
  system: "You are a friendly assistant!",
  prompt: "Why is the sky blue?",
  mode: :event
})

# Process different event types
Enum.reduce_while(result.stream, [], fn
  # Text chunk received - print it and continue
  {:text_delta, chunk}, acc ->
    IO.write(chunk)
    {:cont, [chunk | acc]}
    
  # Stream finished - print reason and halt collection
  {:finish, reason}, acc ->
    IO.puts("\nFinished: #{reason}")
    {:halt, acc}
    
  # Error received - print it and halt collection
  {:error, error}, acc ->
    IO.puts("\nError: #{inspect(error)}")
    {:halt, acc}
    
  # Other events - just continue
  _, acc ->
    {:cont, acc}
end)
```

## Architecture

The Elixir AI SDK follows similar patterns to the original Vercel AI SDK but uses Elixir idioms and patterns:

- Stream-based API for real-time text generation
- Server-Sent Events (SSE) for efficient streaming
- Proper backpressure handling for large responses
- Elixir-native error handling with tagged tuples
- Phoenix integration for web applications

## Development Status

This project is under active development.

## Documentation

- [Streaming Guide](docs/streaming.md) - Real-time text generation with SSE
- Full API documentation available on [HexDocs](https://hexdocs.pm/ai_sdk)