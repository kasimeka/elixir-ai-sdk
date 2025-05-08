defmodule AI.Providers.OpenAI.CompletionLanguageModelTest do
  use ExUnit.Case, async: true
  alias AI.Providers.OpenAI.CompletionLanguageModel
  alias AI.Provider.UnsupportedFunctionalityError

  @test_prompt "Hello"

  @test_logprobs %{
    "tokens" => ["Hello", "!"],
    "token_logprobs" => [-0.0009994634, -0.13410144],
    "top_logprobs" => [
      %{"Hello" => -0.0009994634},
      %{"!" => -0.13410144}
    ]
  }

  setup do
    model = CompletionLanguageModel.new("gpt-3.5-turbo", 
      api_key: "test-api-key",
      compatibility: "strict"
    )
    %{model: model}
  end

  describe "settings" do
    test "should set supports_image_urls to true by default" do
      default_model = CompletionLanguageModel.new("gpt-3.5-turbo")
      assert default_model.supports_image_urls == true
    end

    test "should set supports_image_urls to false when download_images is true" do
      model_with_download_images = CompletionLanguageModel.new("gpt-3.5-turbo", 
        settings: %{download_images: true}
      )
      assert model_with_download_images.supports_image_urls == false
    end

    test "should set supports_image_urls to true when download_images is false" do
      model_without_download_images = CompletionLanguageModel.new("gpt-3.5-turbo", 
        settings: %{download_images: false}
      )
      assert model_without_download_images.supports_image_urls == true
    end
  end

  describe "do_generate" do
    test "should extract text response", %{model: model} do
      response = %{
        "id" => "cmpl-95ZTZkhr0mHNKqerQfiwkuox3PHAd",
        "object" => "text_completion",
        "created" => 1_711_115_037,
        "model" => "gpt-3.5-turbo-0125",
        "choices" => [
          %{
            "index" => 0,
            "text" => "Hello, World!",
            "finish_reason" => "stop"
          }
        ],
        "usage" => %{
          "prompt_tokens" => 4,
          "total_tokens" => 34,
          "completion_tokens" => 30
        },
        "system_fingerprint" => "fp_3bc1b5746c",
        headers: %{},
        body: "{}"
      }

      {:ok, result} = CompletionLanguageModel.do_generate(model, %{
        input_format: "prompt",
        mode: %{type: "regular"},
        prompt: @test_prompt
      }, response)

      assert result.text == "Hello, World!"
    end

    test "should extract usage", %{model: model} do
      response = %{
        "id" => "cmpl-95ZTZkhr0mHNKqerQfiwkuox3PHAd",
        "object" => "text_completion",
        "created" => 1_711_115_037,
        "model" => "gpt-3.5-turbo-0125",
        "choices" => [
          %{
            "index" => 0,
            "text" => "",
            "finish_reason" => "stop"
          }
        ],
        "usage" => %{
          "prompt_tokens" => 20,
          "total_tokens" => 25,
          "completion_tokens" => 5
        },
        "system_fingerprint" => "fp_3bc1b5746c",
        headers: %{},
        body: "{}"
      }

      {:ok, result} = CompletionLanguageModel.do_generate(model, %{
        input_format: "prompt",
        mode: %{type: "regular"},
        prompt: @test_prompt
      }, response)

      assert result.usage == %{
        prompt_tokens: 20,
        completion_tokens: 5
      }
    end

    test "should extract response metadata", %{model: model} do
      response = %{
        "id" => "test-id",
        "object" => "text_completion",
        "created" => 123,
        "model" => "test-model",
        "choices" => [
          %{
            "index" => 0,
            "text" => "",
            "finish_reason" => "stop"
          }
        ],
        "usage" => %{
          "prompt_tokens" => 4,
          "total_tokens" => 34,
          "completion_tokens" => 30
        },
        "system_fingerprint" => "fp_3bc1b5746c",
        headers: %{},
        body: "{}"
      }

      {:ok, result} = CompletionLanguageModel.do_generate(model, %{
        input_format: "prompt",
        mode: %{type: "regular"},
        prompt: @test_prompt
      }, response)

      assert result.response == %{
        id: "test-id",
        timestamp: DateTime.from_unix!(123),
        model_id: "test-model"
      }
    end

    test "should extract logprobs", %{model: model} do
      model_with_logprobs = CompletionLanguageModel.new("gpt-3.5-turbo", 
        settings: %{logprobs: 1}
      )
      
      response = %{
        "id" => "cmpl-95ZTZkhr0mHNKqerQfiwkuox3PHAd",
        "object" => "text_completion",
        "created" => 1_711_115_037,
        "model" => "gpt-3.5-turbo-0125",
        "choices" => [
          %{
            "index" => 0,
            "text" => "",
            "logprobs" => @test_logprobs,
            "finish_reason" => "stop"
          }
        ],
        "usage" => %{
          "prompt_tokens" => 4,
          "total_tokens" => 34,
          "completion_tokens" => 30
        },
        "system_fingerprint" => "fp_3bc1b5746c",
        headers: %{},
        body: "{}"
      }

      {:ok, result} = CompletionLanguageModel.do_generate(model_with_logprobs, %{
        input_format: "prompt",
        mode: %{type: "regular"},
        prompt: @test_prompt
      }, response)

      assert result.logprobs == [
        %{
          token: "Hello",
          logprob: -0.0009994634,
          top_logprobs: [%{token: "Hello", logprob: -0.0009994634}]
        },
        %{
          token: "!",
          logprob: -0.13410144,
          top_logprobs: [%{token: "!", logprob: -0.13410144}]
        }
      ]
    end

    test "should extract finish reason", %{model: model} do
      response = %{
        "id" => "cmpl-95ZTZkhr0mHNKqerQfiwkuox3PHAd",
        "object" => "text_completion",
        "created" => 1_711_115_037,
        "model" => "gpt-3.5-turbo-0125",
        "choices" => [
          %{
            "index" => 0,
            "text" => "",
            "finish_reason" => "stop"
          }
        ],
        "usage" => %{
          "prompt_tokens" => 4,
          "total_tokens" => 34,
          "completion_tokens" => 30
        },
        "system_fingerprint" => "fp_3bc1b5746c",
        headers: %{},
        body: "{}"
      }

      {:ok, result} = CompletionLanguageModel.do_generate(model, %{
        input_format: "prompt",
        mode: %{type: "regular"},
        prompt: @test_prompt
      }, response)

      assert result.finish_reason == "stop"
    end

    test "should handle unknown finish reason", %{model: model} do
      response = %{
        "id" => "cmpl-95ZTZkhr0mHNKqerQfiwkuox3PHAd",
        "object" => "text_completion",
        "created" => 1_711_115_037,
        "model" => "gpt-3.5-turbo-0125",
        "choices" => [
          %{
            "index" => 0,
            "text" => "",
            "finish_reason" => "eos"
          }
        ],
        "usage" => %{
          "prompt_tokens" => 4,
          "total_tokens" => 34,
          "completion_tokens" => 30
        },
        "system_fingerprint" => "fp_3bc1b5746c",
        headers: %{},
        body: "{}"
      }

      {:ok, result} = CompletionLanguageModel.do_generate(model, %{
        input_format: "prompt",
        mode: %{type: "regular"},
        prompt: @test_prompt
      }, response)

      assert result.finish_reason == "unknown"
    end

    test "should handle unsupported functionality", %{model: model} do
      assert_raise UnsupportedFunctionalityError, fn ->
        CompletionLanguageModel.get_args(model, %{
          input_format: "prompt",
          mode: %{type: "object-json"},
          prompt: @test_prompt
        })
      end
    end
  end
end 