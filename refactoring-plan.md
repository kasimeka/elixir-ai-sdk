# Elixir AI SDK Streaming Refactoring Plan

## Overview

This document outlines a plan to refactor the streaming capabilities of the Elixir AI SDK, applying lessons learned from the Vercel AI SDK architecture. The goal is to improve maintainability, standardize provider interfaces, and create a more extensible system.

## Key Components to Implement

1. **Event Source Module Refactoring**
   - Remove debug output (`IO.puts` statements)
   - Replace with proper `Logger` calls
   - Eliminate global agent usage

2. **Standard Stream Event Types**
   - Create structs for different event types (TextDelta, ToolCall, etc.)
   - Standardize event format across all providers
   - Include proper typespecs

3. **Provider Registry Pattern**
   - Implement GenServer-based provider registry
   - Support provider:model notation
   - Enable dynamic provider registration

4. **Provider-Specific Stream Transformers**
   - Create transformer modules for each provider
   - Standardize transformation of provider-specific formats
   - Support proper error handling

5. **Middleware System**
   - Implement function-based middleware pattern
   - Support composable middleware
   - Include logging middleware

6. **Error Handling**
   - Create standard error types
   - Implement consistent error wrapping
   - Include detailed error information

7. **API Updates**
   - Update model creation interface
   - Ensure backward compatibility
   - Support middleware application

## TDD Implementation Guidance

To ensure Claude Code follows a strict test-driven development approach with small, incremental changes, follow these guidelines:

### General TDD Rules

1. **Single Module Focus**: Work on one module at a time (not multiple modules in parallel)
2. **Three-Phase Cycle**: For each feature:
   - Write a failing test first (RED)
   - Implement minimum code to pass the test (GREEN)
   - Refactor while keeping tests passing (REFACTOR)
3. **Run Tests Immediately**: Run tests after each change
4. **Commit Working Increments**: Commit code only when tests pass

### Implementation Process

For each module:

1. **Start with Test File**: Create the test file first with 1-2 basic tests
2. **Run Tests and Verify Failure**: Ensure tests fail appropriately
3. **Implement Minimal Module**: Add just enough code to make tests pass
4. **Run Tests Again**: Verify tests now pass
5. **Add More Tests**: Incrementally add more test cases
6. **Expand Implementation**: Gradually implement more functionality
7. **Verify Integration**: Add integration tests only after unit tests pass

### Specific Work Breakdown

#### 1. EventSource Module Refactoring

```
1. Create separate branch for EventSource changes
2. Write test for EventSource without IO.puts
3. Replace IO.puts with Logger in small batches
4. Run tests after each batch
5. Fix global agent usage
6. Add tests for new behavior
7. Run full test suite
```

#### 2. Stream Event Types

```
1. Create test file with basic struct tests
2. Implement minimal Event structs
3. Run tests to verify
4. Add tests for each event type
5. Implement remaining functionality
6. Add serialization/deserialization tests
7. Implement those features
8. Run full test suite
```

#### 3. Provider Registry

```
1. Create test file for registry
2. Write basic process tests
3. Implement minimal registry
4. Run tests to verify
5. Add tests for registration
6. Implement registration
7. Add tests for retrieval
8. Implement retrieval
9. Run full test suite
```

And so on for each component...

## Implementation Details

### Stream Event Types

```elixir
defmodule AI.Stream.Event do
  @type t :: TextDelta.t() | ToolCall.t() | Finish.t() | Metadata.t() | Error.t()
  
  defmodule TextDelta do
    @enforce_keys [:content]
    defstruct [:content]
  end
  
  defmodule ToolCall do
    @enforce_keys [:id, :name, :arguments]
    defstruct [:id, :name, :arguments]
  end
  
  defmodule Finish do
    @enforce_keys [:reason]
    defstruct [:reason]
  end
  
  defmodule Metadata do
    @enforce_keys [:data]
    defstruct [:data]
  end
  
  defmodule Error do
    @enforce_keys [:error]
    defstruct [:error]
  end
end
```

### Provider Registry

```elixir
defmodule AI.ProviderRegistry do
  use GenServer
  
  # Client API
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def register(provider_id, provider_module, opts \\ [])
  def get_provider(provider_id)
  def get_language_model(model_id) when is_binary(model_id)
  
  # Server callbacks
  @impl true
  def init(_opts), do: {:ok, %{providers: %{}}}
  
  @impl true
  def handle_call({:register, id, module, opts}, _from, state)
  @impl true
  def handle_call({:get_provider, id}, _from, state)
end
```

### Stream Transformer

```elixir
defmodule AI.Providers.OpenAI.StreamTransformer do
  alias AI.Stream.Event
  
  def process(data) when is_binary(data)
  def transform(%{"choices" => [%{"delta" => %{"content" => content}} | _]})
  def transform(%{"choices" => [%{"delta" => %{"tool_calls" => tool_calls}} | _]})
  def transform(%{"choices" => [%{"finish_reason" => reason} | _]})
  def transform(json)
end
```

### Middleware Pattern

```elixir
defmodule AI.Middleware do
  @spec apply(model :: struct(), middleware :: function()) :: struct()
  def apply(model, middleware)
  
  @spec compose(middlewares :: [function()]) :: function()
  def compose(middlewares) when is_list(middlewares)
  
  @spec logging(opts :: keyword()) :: function()
  def logging(opts \\ [])
end
```

### Updated API

```elixir
defmodule AI do
  def get_model(model_id, opts \\ []) when is_binary(model_id)
  
  # Backward compatibility
  def openai(model_id, opts \\ [])
  def openai_compatible(model_id, base_url, opts \\ [])
end
```

## Sample Test Templates

### Event Struct Tests

```elixir
defmodule AI.Stream.EventTest do
  use ExUnit.Case

  describe "TextDelta" do
    test "creates a text delta event" do
      event = %AI.Stream.Event.TextDelta{content: "Hello"}
      assert event.content == "Hello"
    end
    
    # More tests...
  end
  
  # Tests for other event types...
end
```

### Provider Registry Tests

```elixir
defmodule AI.ProviderRegistryTest do
  use ExUnit.Case
  
  setup do
    # Start registry for each test
    {:ok, pid} = AI.ProviderRegistry.start_link()
    %{registry_pid: pid}
  end
  
  test "registers a provider" do
    assert :ok == AI.ProviderRegistry.register("test", TestProvider)
    assert {:ok, _provider} = AI.ProviderRegistry.get_provider("test")
  end
  
  # More tests...
end
```

## Implementation Priority

1. Stream Event Types (simplest to implement, foundation for other components)
2. EventSource Module Refactoring (high priority issue)
3. Provider Registry Pattern
4. Error Handling
5. Stream Transformers
6. Middleware System
7. API Updates
8. Documentation

## Expected Benefits

- Improved maintainability through removal of debug statements
- Better extensibility through standardized provider interfaces
- Cleaner error handling with consistent patterns
- More flexible configuration through middleware
- Easier integration of new providers

## Instructions for Claude Code

1. Work on ONE module at a time
2. For each module:
   - Create test file first with a SINGLE test case
   - Implement minimum code to pass
   - Run the test
   - Only after test passes, add more tests incrementally
   - Expand implementation as needed
3. DO NOT implement multiple modules at once
4. After completing each module:
   - Run the full test suite
   - Commit changes
   - Only then move to the next module
5. If a test fails:
   - Focus solely on fixing that test
   - Do not continue until ALL tests pass

This strict TDD approach ensures incremental progress with working code at each step.