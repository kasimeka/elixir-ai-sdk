# Coordination Guide for Porting Vercel AI SDK to Elixir

This guide helps coordinating agents identify, prioritize, and delegate porting tasks from the Vercel AI SDK to the Elixir implementation.

## Identifying Features to Port

### Step 1: Feature Inventory

1. **Core Functionality Identification**:
   - Review the Vercel AI SDK structure in `/packages/ai/`
   - Focus specifically on the core model interaction capabilities
   - Identify standalone features that can be ported independently
   - Document each feature and its primary functions

2. **Feature Categorization**:
   - **Core LLM Interactions**: Essential text generation, chat, etc.
   - **Tool & Function Calling**: Tool definitions, execution, etc.
   - **Prompt Engineering**: Helpers for constructing prompts
   - **Streaming**: Functionality for streaming responses
   - **Error Handling**: Error types and handling strategies
   - **Provider Integrations**: APIs for specific LLM providers

3. **Framework-Specific Features** (to exclude):
   - React/UI-specific components
   - Next.js integrations
   - Browser-specific functionality
   - RSC (React Server Components)
   - Other JavaScript framework integrations

### Step 2: Dependency Analysis

1. **Dependency Mapping**:
   - For each identified feature, map dependencies on other features
   - Create a directed graph showing prerequisite relationships
   - Identify foundation features that many others depend on
   - Note independent features that can be ported in isolation

2. **External Dependencies**:
   - Identify TypeScript/JavaScript libraries used by each feature
   - Determine Elixir equivalents for necessary libraries
   - Flag features requiring external dependencies without Elixir alternatives

## Prioritization Strategy

Evaluate features along three dimensions:

### 1. Value Assessment (High/Medium/Low)

- **High Value**:
  - Core text generation and chat functionality
  - Streaming capabilities
  - Error handling
  - Essential prompt construction
  - Tool calling (function calling)
  - OpenAI and OpenAI-compatible provider support

- **Medium Value**:
  - Advanced prompt engineering
  - Anthropic provider support
  - Basic caching mechanisms
  - Token usage tracking

- **Low Value**:
  - Specialized model capabilities (vision, audio)
  - Niche provider integrations
  - Complex browser integrations

### 2. Implementation Effort (High/Medium/Low)

- **Low Effort**:
  - Simple data structures
  - Straightforward conversions
  - Features with existing Elixir analogues

- **Medium Effort**:
  - Features requiring moderate restructuring
  - Custom type definitions
  - Basic streaming implementations

- **High Effort**:
  - Complex async operations
  - JS-specific paradigms with no direct Elixir equivalent
  - Multiple interdependent components

### 3. Prerequisite Dependencies (Many/Some/None)

- Count how many other features depend on this one
- Note whether this feature blocks high-value implementations

## Prioritization Matrix

Use this matrix to determine porting order, focusing on the top-right quadrant:

```
          │ Low Effort  │ Medium Effort │ High Effort
──────────┼─────────────┼───────────────┼────────────
High Value│ PRIORITY 1  │  PRIORITY 2   │ PRIORITY 4
──────────┼─────────────┼───────────────┼────────────
Med Value │ PRIORITY 3  │  PRIORITY 5   │ PRIORITY 7
──────────┼─────────────┼───────────────┼────────────
Low Value │ PRIORITY 6  │  PRIORITY 8   │ EXCLUDE
```

Additional considerations:
- Promote features with no/few dependencies
- Delay features with many dependencies until prerequisites are ported
- Features in the EXCLUDE category should only be considered if explicitly requested

## Delegation Process

### Package Preparation

1. Create directory structure mirroring core Vercel SDK organization
2. Establish placeholder modules with documentation for features to be ported
3. Create mix tasks to help with code generation if needed

### Task Assignment

For each feature, create a task description including:

1. **Feature Overview**:
   - Brief description of functionality
   - Link to original TypeScript implementation
   - Reference to any existing Elixir code that interacts with it

2. **Implementation Scope**:
   - Clear boundaries of what to include and exclude
   - Specific files/modules to create
   - Interface definitions and function signatures

3. **Dependencies**:
   - Required prerequisite features
   - External libraries needed

4. **Testing Focus**:
   - Key test cases to implement
   - Edge cases to consider
   - Performance considerations

### Task Tracking

Create a roadmap document with:
- Prioritized feature list
- Status (Not Started, In Progress, Complete)
- Dependencies and blockers
- Assigned developers/agents
- Estimated complexity

## Features to Exclude

Explicitly document features that should NOT be ported:

1. **UI Framework Integrations**:
   - React hooks and components
   - Svelte, Vue, Solid integrations
   - RSC (React Server Components)

2. **Web-Specific Features**:
   - Browser-only functionality
   - Client-side processing

3. **Provider Scope Limitation**:
   - Only port OpenAI, OpenAI-compatible, and Anthropic providers
   - Document provider interface for community extensions
   - Exclude specialized providers (image, embedding-only, etc.)

4. **Framework-Specific Features**:
   - Next.js specific functionality
   - Express/Fastify/Hono integrations

## Implementation Guidelines

### Phase 1: Foundation (First Implementation Sprint)

Focus on these core capabilities first:
- Basic text generation with OpenAI-compatible providers
- Core message types and formatting
- Error handling foundation
- Simple prompt construction

### Phase 2: Enhanced Capabilities (Second Sprint)

Once foundations are solid, add:
- Tool/function calling
- Streaming responses
- Anthropic Claude support
- Advanced prompt features

### Phase 3: Optimization (Final Sprint)

After core functionality is working:
- Caching implementations
- Performance optimizations
- Token usage tracking
- Advanced error handling

## Community Extension Strategy

Create documentation for:
- Adding new providers
- Implementing specialized capabilities
- Contributing best practices

This approach focuses on building a solid core that the community can extend with additional providers and specialized capabilities.