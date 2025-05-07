# OpenAI-Compatible Provider Test Plan

## 1. Provider Configuration Tests

- [x] 1.1 Should create provider with correct configuration (baseURL, name, apiKey, headers) - `packages/openai-compatible/src/openai-compatible-provider.test.ts:34-60`
- [x] 1.2 Should create headers without Authorization when no apiKey provided - `packages/openai-compatible/src/openai-compatible-provider.test.ts:62-80`
- [x] 1.3 Should remove trailing slash from baseURL - `packages/openai-compatible/src/openai-compatible-provider.test.ts:106-111` (part of URL tests)
- [x] 1.4 Should handle url with query parameters - `packages/openai-compatible/src/openai-compatible-provider.test.ts:121-132`
- [x] 1.5 Should create URL without query parameters when queryParams is not specified - `packages/openai-compatible/src/openai-compatible-provider.test.ts:170-188`
- [x] 1.6 Should require baseURL parameter - Not directly tested in original, inferred from implementation

## 2. Model Creation Tests

- [x] 2.1 Should create a chat model with correct configuration - `packages/openai-compatible/src/openai-compatible-provider.test.ts:92-111`
- ~~[-] 2.2 Should create preset models with appropriate defaults (LMStudio, Ollama) - Not in original tests, specific to our implementation~~
- [x] 2.3 Should handle provider name formatting correctly - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:27-68`

## 3. Message Conversion Tests

- [x] 3.1 Should convert messages with only text parts to string content - `packages/openai-compatible/src/convert-to-openai-compatible-chat-messages.test.ts:4-13`
- [x] 3.2 Should convert user messages with proper roles - `packages/openai-compatible/src/convert-to-openai-compatible-chat-messages.test.ts:44-69`
- [x] 3.3 Should convert system messages correctly - `packages/openai-compatible/src/convert-to-openai-compatible-chat-messages.test.ts:124-144`
- [x] 3.4 Should stringify arguments to tool calls - `packages/openai-compatible/src/convert-to-openai-compatible-chat-messages.test.ts:72-120`
- [x] 3.5 Should convert tool result messages correctly - `packages/openai-compatible/src/convert-to-openai-compatible-chat-messages.test.ts:425-466`

## 4. Generate Text Tests

- [x] 4.1 Should extract text response from API response - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:162-173`
- [x] 4.2 Should extract reasoning content when available - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:175-191`
- [x] 4.3 Should extract usage statistics - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:193-209`
- [x] 4.4 Should extract finish reason - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:248-261`
- [x] 4.5 Should handle unknown finish reason - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:263-277`
- [x] 4.6 Should pass the model ID and messages correctly - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:299-313`
- [x] 4.7 Should extract tool calls from response - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:456-503`
- [x] 4.8 Should build appropriate request with tools and toolChoice - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:373-425`
- [x] 4.9 Should include provider-specific options in request - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:336-370`
- [x] 4.10 Should send appropriate headers - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:427-454`
- [x] 4.11 Should handle API errors correctly - Not directly tested in original, inferred from implementation

## 5. Streaming Tests

- [ ] 5.1 Should stream text deltas correctly - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1047-1080`
- [ ] 5.2 Should stream reasoning content before text deltas - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1082-1139`
- [ ] 5.3 Should handle streamed tool calls - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1141-1198`
- [ ] 5.4 Should process complete tool calls from a single chunk - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1540-1608`
- [ ] 5.5 Should handle tool calls sent across multiple chunks - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1198-1362`
- [ ] 5.6 Should not duplicate tool calls with empty chunks - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1412-1538`
- [ ] 5.7 Should handle error stream parts - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1609-1642`
- [ ] 5.8 Should handle unparsable stream parts - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1644-1671`
- [ ] 5.9 Should pass stream configuration in requests - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1015-1045`
- [ ] 5.10 Should extract usage statistics from stream - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1798-1880`
- [ ] 5.11 Should include provider-specific options in streamed requests - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1742-1780`

## 6. Simulated Streaming Tests

- [ ] 6.1 Should simulate streaming for text responses - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1944-1976`
- [ ] 6.2 Should simulate streaming with reasoning content - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:1978-2020`
- [ ] 6.3 Should simulate streaming tool calls - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:2022-2085`

## 7. Response Format Tests

- [ ] 7.1 Should handle response_format for JSON outputs - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:505-546`
- [ ] 7.2 Should handle JSON mode tools correctly - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:735-875`

## 8. Error Handling Tests

- [ ] 8.1 Should handle API errors with proper error structures - Not directly tested in original, inferred from implementation
- [ ] 8.2 Should handle timeout errors - Not directly tested in original, inferred from implementation
- [ ] 8.3 Should handle network errors - Not directly tested in original, inferred from implementation
- [ ] 8.4 Should handle invalid responses - Not directly tested in original, inferred from implementation

## 9. Helper Functions Tests

- [ ] 9.1 Should build messages from prompts correctly - Tested as part of other test cases
- [ ] 9.2 Should format tools correctly - Tested as part of tools request tests
- [ ] 9.3 Should format tool_choice correctly - Tested as part of tools request tests
- [ ] 9.4 Should process response data correctly - Tested through extract tests
- [ ] 9.5 Should extract token usage details - `packages/openai-compatible/src/openai-compatible-chat-language-model.test.ts:903-979`