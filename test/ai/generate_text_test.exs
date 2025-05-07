defmodule AI.GenerateTextTest do
  use ExUnit.Case, async: true

  alias AI.Core.MockLanguageModel

  # Mock model setup
  setup do
    # This is similar to the dummyResponseValues in the JS tests
    dummy_response_values = %{
      raw_call: %{raw_prompt: "prompt", raw_settings: %{}},
      finish_reason: "stop",
      usage: %{prompt_tokens: 10, completion_tokens: 20, total_tokens: 30}
    }

    model =
      MockLanguageModel.new(%{
        do_generate: fn _opts ->
          {:ok, Map.merge(dummy_response_values, %{text: "Hello, world!"})}
        end
      })

    model_with_reasoning =
      MockLanguageModel.new(%{
        do_generate: fn _opts ->
          {:ok,
           Map.merge(dummy_response_values, %{
             reasoning: [
               %{
                 type: "text",
                 text: "I will open the conversation with witty banter.",
                 signature: "signature"
               },
               %{
                 type: "redacted",
                 data: "redacted-reasoning-data"
               }
             ],
             text: "Hello, world!"
           })}
        end
      })

    model_with_sources =
      MockLanguageModel.new(%{
        do_generate: fn _opts ->
          {:ok,
           Map.merge(dummy_response_values, %{
             sources: [
               %{
                 source_type: "url",
                 id: "123",
                 url: "https://example.com",
                 title: "Example",
                 provider_metadata: %{provider: %{custom: "value"}}
               },
               %{
                 source_type: "url",
                 id: "456",
                 url: "https://example.com/2",
                 title: "Example 2",
                 provider_metadata: %{provider: %{custom: "value2"}}
               }
             ],
             text: "Hello, world!"
           })}
        end
      })

    model_with_files =
      MockLanguageModel.new(%{
        do_generate: fn _opts ->
          {:ok,
           Map.merge(dummy_response_values, %{
             files: [
               %{
                 data: <<1, 2, 3>>,
                 mime_type: "image/png"
               },
               %{
                 # Base64 encoded data
                 data: "QkFVRw==",
                 mime_type: "image/jpeg"
               }
             ],
             text: "Hello, world!"
           })}
        end
      })

    {:ok,
     %{
       model: model,
       model_with_reasoning: model_with_reasoning,
       model_with_sources: model_with_sources,
       model_with_files: model_with_files
     }}
  end

  describe "basic text generation" do
    test "should generate text", %{model: model} do
      {:ok, result} =
        AI.generate_text(%{
          model: model,
          prompt: "prompt"
        })

      assert result.text == "Hello, world!"
    end
  end

  describe "reasoning features" do
    test "should contain reasoning string from model response", %{model_with_reasoning: model} do
      {:ok, result} =
        AI.generate_text(%{
          model: model,
          prompt: "prompt"
        })

      assert result.reasoning == "I will open the conversation with witty banter."
    end
  end

  describe "sources features" do
    test "should contain sources from model response", %{model_with_sources: model} do
      {:ok, result} =
        AI.generate_text(%{
          model: model,
          prompt: "prompt"
        })

      assert length(result.sources) == 2

      [source1, source2] = result.sources

      assert source1.source_type == "url"
      assert source1.id == "123"
      assert source1.url == "https://example.com"
      assert source1.title == "Example"

      assert source2.source_type == "url"
      assert source2.id == "456"
      assert source2.url == "https://example.com/2"
      assert source2.title == "Example 2"
    end
  end

  describe "file features" do
    test "should contain files from model response", %{model_with_files: model} do
      {:ok, result} =
        AI.generate_text(%{
          model: model,
          prompt: "prompt"
        })

      assert length(result.files) == 2

      [file1, file2] = result.files

      assert file1.mime_type == "image/png"
      assert file1.data == <<1, 2, 3>>

      assert file2.mime_type == "image/jpeg"
      assert file2.data == "QkFVRw=="
    end
  end
end
