defmodule AI.Provider.UnsupportedFunctionalityError do
  @moduledoc """
  Error raised when a functionality is not supported by the model.
  """

  defexception [:functionality]

  @type t :: %__MODULE__{
          functionality: String.t()
        }

  def message(%__MODULE__{functionality: functionality}) do
    "Functionality not supported: #{functionality}"
  end
end
