defmodule JaviWeb.Helpers do
  @moduledoc """
  Helper functions for the web interface.
  """
  defmacro __using__(_opts) do
    quote do
      import JaviWeb.Helpers.LiveHelper
    end
  end
end
