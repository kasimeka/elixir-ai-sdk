defmodule AI.Provider.Utils.Headers do
  @moduledoc """
  Utility functions for handling HTTP headers.
  """

  def combine(default_headers, additional_headers) do
    Map.merge(default_headers, additional_headers)
  end
end 