defmodule AI.Provider.UnsupportedFunctionalityError do
  @moduledoc """
  Exception raised when a functionality is not supported.
  """

  defexception message: "Unsupported functionality"
end
