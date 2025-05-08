defmodule AI.Providers.OpenAI.CompletionLanguageModel do
  @moduledoc """
  Implementation of the OpenAI Completion Language Model.
  """

  alias AI.Provider.UnsupportedFunctionalityError
  alias AI.Provider.Utils.JsonApi

  defstruct [
    :model,
    :api_key,
    :compatibility,
    :settings,
    supports_image_urls: true
  ]

  @type t :: %__MODULE__{
    model: String.t(),
    api_key: String.t(),
    compatibility: String.t(),
    settings: map(),
    supports_image_urls: boolean()
  }

  @doc """
  Creates a new completion model instance.
  """
  def new(model, opts \\ []) do
    settings = Keyword.get(opts, :settings, %{})
    supports_image_urls = !Map.get(settings, :download_images, false)

    %__MODULE__{
      model: model,
      api_key: Keyword.get(opts, :api_key),
      compatibility: Keyword.get(opts, :compatibility, "strict"),
      settings: settings,
      supports_image_urls: supports_image_urls
    }
  end

  @doc """
  Generates a response from the model.
  """
  def do_generate(_model, options, response) do
    with {:ok, text} <- extract_text(response),
         {:ok, usage} <- extract_usage(response),
         {:ok, response_metadata} <- extract_response_metadata(response),
         {:ok, logprobs} <- extract_logprobs(response),
         {:ok, finish_reason} <- extract_finish_reason(response) do
      {:ok, %{
        text: text,
        usage: usage,
        response: response_metadata,
        logprobs: logprobs,
        finish_reason: finish_reason,
        raw_call: %{
          raw_prompt: options.prompt,
          raw_settings: Map.drop(options, [:prompt])
        },
        raw_response: %{
          headers: response.headers,
          body: response.body
        }
      }}
    end
  end

  @doc """
  Streams a response from the model.
  """
  def do_stream(model, options) do
    with {:ok, args} <- get_args(model, options),
         {:ok, response} <- JsonApi.post(
           "/completions",
           Map.put(args, :stream, true),
           [{"Authorization", "Bearer #{model.api_key}"} | options.headers],
           stream: true
         ) do
      {:ok, %{
        stream: response,
        raw_call: %{
          raw_prompt: options.prompt,
          raw_settings: Map.drop(options, [:prompt])
        },
        raw_response: %{
          headers: response.headers
        }
      }}
    end
  end

  defp extract_text(%{"choices" => [%{"text" => text} | _]}) do
    {:ok, text}
  end
  defp extract_text(_), do: {:error, "Invalid response structure"}

  defp extract_usage(%{"usage" => usage}) do
    {:ok, %{
      prompt_tokens: usage["prompt_tokens"],
      completion_tokens: usage["completion_tokens"]
    }}
  end
  defp extract_usage(_), do: {:error, "Invalid usage structure"}

  defp extract_response_metadata(%{
    "id" => id,
    "created" => created,
    "model" => model
  }) do
    {:ok, %{
      id: id,
      timestamp: DateTime.from_unix!(created),
      model_id: model
    }}
  end
  defp extract_response_metadata(_), do: {:error, "Invalid response metadata structure"}

  defp extract_logprobs(%{"choices" => [%{"logprobs" => logprobs} | _]}) when not is_nil(logprobs) do
    {:ok, Enum.zip_with(
      [logprobs["tokens"], logprobs["token_logprobs"], logprobs["top_logprobs"]],
      fn [token, logprob, top_logprobs] ->
        %{
          token: token,
          logprob: logprob,
          top_logprobs: Enum.map(top_logprobs, fn {token, logprob} ->
            %{token: token, logprob: logprob}
          end)
        }
      end
    )}
  end
  defp extract_logprobs(_), do: {:ok, nil}

  defp extract_finish_reason(%{"choices" => [%{"finish_reason" => reason} | _]}) do
    case reason do
      "stop" -> {:ok, "stop"}
      "length" -> {:ok, "length"}
      "content_filter" -> {:ok, "content_filter"}
      "tool_calls" -> {:ok, "tool_calls"}
      _ -> {:ok, "unknown"}
    end
  end
  defp extract_finish_reason(_), do: {:error, "Invalid finish reason structure"}

  @doc """
  Gets the arguments for the API call.
  """
  def get_args(model, %{mode: %{type: type}} = options) do
    case type do
      "regular" ->
        if get_in(options, [:mode, :tools]) do
          raise %UnsupportedFunctionalityError{functionality: "tools"}
        end
        if get_in(options, [:mode, :tool_choice]) do
          raise %UnsupportedFunctionalityError{functionality: "toolChoice"}
        end
        {:ok, get_base_args(model, options)}

      "object-json" ->
        raise %UnsupportedFunctionalityError{functionality: "object-json mode"}

      "object-tool" ->
        raise %UnsupportedFunctionalityError{functionality: "object-tool mode"}

      _ ->
        raise "Unsupported type: #{type}"
    end
  end

  defp get_base_args(model, %{
    prompt: prompt,
    max_tokens: max_tokens,
    temperature: temperature,
    top_p: top_p,
    frequency_penalty: frequency_penalty,
    presence_penalty: presence_penalty,
    stop_sequences: stop_sequences,
    seed: seed
  }) do
    %{
      model: model.model,
      prompt: prompt,
      max_tokens: max_tokens,
      temperature: temperature,
      top_p: top_p,
      frequency_penalty: frequency_penalty,
      presence_penalty: presence_penalty,
      stop: stop_sequences,
      seed: seed,
      echo: model.settings.echo,
      logit_bias: model.settings.logit_bias,
      logprobs: get_logprobs_setting(model.settings.logprobs),
      suffix: model.settings.suffix,
      user: model.settings.user
    }
  end

  defp get_logprobs_setting(nil), do: nil
  defp get_logprobs_setting(true), do: 0
  defp get_logprobs_setting(false), do: nil
  defp get_logprobs_setting(n) when is_integer(n), do: n
end 