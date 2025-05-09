defmodule AI.Providers.OpenAI.CompletionLanguageModel do
  @moduledoc """
  Implementation of the OpenAI completion language model.
  """

  alias AI.Provider.{LanguageModelV1, UnsupportedFunctionalityError}
  alias AI.Provider.Utils.{Headers, JsonApi, EventSource}

  @behaviour LanguageModelV1

  @type t :: %__MODULE__{
          model_id: String.t(),
          settings: map(),
          config: map()
        }

  defstruct [:model_id, :settings, :config]

  @impl LanguageModelV1
  def specification_version, do: "v1"

  @impl LanguageModelV1
  def default_object_generation_mode(_model), do: :tool

  @impl LanguageModelV1
  def supports_image_urls?(_model), do: true

  @impl LanguageModelV1
  def supports_structured_outputs?(_model), do: false

  @doc """
  Creates a new OpenAI completion language model instance with default settings.
  """
  def new(model_id) do
    # Get API key from environment variable
    api_key = System.get_env("OPENAI_API_KEY")

    new(model_id, %{}, %{
      provider: "openai",
      headers: fn ->
        %{"Authorization" => "Bearer #{api_key}", "Content-Type" => "application/json"}
      end,
      url: fn %{path: path} -> "https://api.openai.com/v1#{path}" end
    })
  end

  @doc """
  Creates a new OpenAI completion language model instance with custom settings and config.
  """
  def new(model_id, settings, config) do
    %__MODULE__{
      model_id: model_id,
      settings: settings,
      config: config
    }
  end

  @impl LanguageModelV1
  def provider(%__MODULE__{config: config}), do: config.provider

  @impl LanguageModelV1
  def do_generate(%__MODULE__{} = model, options) do
    # Convert input options to the format expected by this module
    adapted_options = convert_options(options)

    {body, warnings} = get_args(model, adapted_options)

    url = get_url(model, "/completions")
    headers = get_headers(model, adapted_options)

    case JsonApi.post(url, body, headers, adapted_options) do
      {:ok, response} ->
        handle_generate_response(response, body, warnings)

      {:error, error} ->
        {:error, error}
    end
  end

  # Convert options from the general format used by AI.generate_text
  # to the specific format expected by this module's get_args function
  defp convert_options(options) do
    # Extract prompt from messages
    prompt =
      case options[:messages] do
        [%{role: "user", content: content}] -> content
        _ -> raise "Completion models only support a single user message"
      end

    # Return the adapted options in the format expected by get_args
    %{
      mode: %{type: "regular"},
      prompt: prompt,
      max_tokens: Map.get(options, :max_tokens, 1024),
      temperature: Map.get(options, :temperature, 0.7),
      top_p: Map.get(options, :top_p, 1.0),
      top_k: Map.get(options, :top_k),
      frequency_penalty: Map.get(options, :frequency_penalty, 0.0),
      presence_penalty: Map.get(options, :presence_penalty, 0.0),
      stop_sequences: Map.get(options, :stop_sequences),
      response_format: Map.get(options, :response_format),
      seed: Map.get(options, :seed),
      provider_metadata: Map.get(options, :provider_metadata, %{})
    }
  end

  @impl LanguageModelV1
  def do_stream(%__MODULE__{settings: %{simulate_streaming: true}} = model, options) do
    # We don't need to use adapted_options here since we're calling do_generate
    # which will convert the options itself
    case do_generate(model, options) do
      {:ok, result} ->
        stream = simulate_stream(result)
        {:ok, %{stream: stream, raw_call: result.raw_call, warnings: result.warnings}}

      error ->
        error
    end
  end

  def do_stream(%__MODULE__{} = model, options) do
    # Convert options for consistency with do_generate
    adapted_options = convert_options(options)

    {body, warnings} = get_args(model, adapted_options)
    body = Map.put(body, :stream, true)

    url = get_url(model, "/completions")
    headers = get_headers(model, adapted_options)

    case EventSource.post(url, body, headers, adapted_options) do
      {:ok, %{body: response_body, status: status}} when status in 200..299 ->
        handle_stream_response(response_body, body, warnings, model.settings)

      {:ok, %{body: error_body, status: status}} ->
        {:error, "HTTP #{status}: #{error_body}"}
    end
  end

  # Private functions

  defp get_args(model, %{
         mode: mode,
         prompt: prompt,
         max_tokens: max_tokens,
         temperature: temperature,
         top_p: top_p,
         top_k: top_k,
         frequency_penalty: frequency_penalty,
         presence_penalty: presence_penalty,
         stop_sequences: stop_sequences,
         response_format: _response_format,
         seed: seed,
         provider_metadata: provider_metadata
       }) do
    warnings = []

    warnings =
      if top_k != nil,
        do: [%{type: :unsupported_setting, setting: :top_k} | warnings],
        else: warnings

    # Build the base arguments map but omit null values
    base_args_with_nulls = %{
      model: model.model_id,
      logit_bias: get_in(model.settings, [:logit_bias]),
      logprobs: get_logprobs_setting(model.settings),
      top_logprobs: get_top_logprobs_setting(model.settings),
      user: get_in(model.settings, [:user]),
      max_tokens: max_tokens,
      temperature: temperature,
      top_p: top_p,
      frequency_penalty: frequency_penalty,
      presence_penalty: presence_penalty,
      stop: stop_sequences,
      seed: seed,
      prompt: prompt
    }

    # Remove nil values to avoid API errors
    base_args = Map.reject(base_args_with_nulls, fn {_k, v} -> v == nil end)

    base_args = maybe_add_openai_specific_settings(base_args, provider_metadata)

    args =
      case mode.type do
        "regular" ->
          {base_args, warnings}

        "object-json" ->
          {:error, %UnsupportedFunctionalityError{functionality: "object-json mode"}}

        "object-tool" ->
          {:error, %UnsupportedFunctionalityError{functionality: "object-tool mode"}}

        _ ->
          {:error,
           %UnsupportedFunctionalityError{functionality: "Unsupported mode type: #{mode.type}"}}
      end

    args
  end

  defp get_url(%__MODULE__{config: config, model_id: model_id}, path) do
    config.url.(%{model_id: model_id, path: path})
  end

  defp get_headers(%__MODULE__{config: config}, options) do
    Headers.combine(config.headers.(), Map.get(options, :headers, %{}))
  end

  defp get_logprobs_setting(settings) do
    case settings do
      %{logprobs: true} -> true
      %{logprobs: n} when is_integer(n) -> true
      _ -> nil
    end
  end

  defp get_top_logprobs_setting(settings) do
    case settings do
      %{logprobs: n} when is_integer(n) -> n
      %{logprobs: true} -> 0
      _ -> nil
    end
  end

  defp maybe_add_openai_specific_settings(args, metadata) do
    openai_metadata = get_in(metadata, [:openai]) || %{}

    args
    |> maybe_put(:max_completion_tokens, openai_metadata[:max_completion_tokens])
    |> maybe_put(:store, openai_metadata[:store])
    |> maybe_put(:metadata, openai_metadata[:metadata])
    |> maybe_put(:prediction, openai_metadata[:prediction])
  end

  # Helper to add a value to a map only if the value is not nil
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp handle_generate_response(response, body, warnings) do
    # Extract the first choice from the response
    first_choice = get_in(response, ["choices", Access.at(0)])

    # Extract the text content
    text = get_in(first_choice, ["text"])

    # Extract finish reason
    finish_reason = get_in(first_choice, ["finish_reason"])

    # Extract usage statistics
    usage = %{
      prompt_tokens: get_in(response, ["usage", "prompt_tokens"]) || 0,
      completion_tokens: get_in(response, ["usage", "completion_tokens"]) || 0,
      total_tokens: get_in(response, ["usage", "total_tokens"]) || 0
    }

    # Create the result
    {:ok,
     %{
       text: text || "",
       finish_reason: finish_reason || "stop",
       usage: usage,
       raw_call: body,
       warnings: warnings
     }}
  end

  defp handle_stream_response(_response, body, warnings, _settings) do
    # TODO: Implement stream response handling
    {:ok, %{stream: %{}, raw_call: body, warnings: warnings}}
  end

  defp simulate_stream(_result) do
    # TODO: Implement stream simulation
    %{}
  end
end
