defmodule JaviWeb.Helpers.LiveHelper do
  import Phoenix.Component
  alias Javi.Accounts

  @moduledoc """
  Helper functions for LiveView operations.
  """

  @doc """
  Returns a tuple with :ok and socket for LiveView operations.
  """
  def ok(socket), do: {:ok, socket}

  @doc """
  Returns a tuple with :noreply and socket for LiveView operations.
  """
  def noreply(socket), do: {:noreply, socket}

  @doc """
  Gets the current user from session.
  """
  def assign_current_user(socket, %{"user_token" => user_token} = _session) do
    user_token
    |> Accounts.get_user_by_session_token()
    |> then(&assign(socket, :current_user, &1))
  end

  def assign_current_user(socket, _session), do: socket
end
