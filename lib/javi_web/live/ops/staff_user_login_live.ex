defmodule JaviWeb.Ops.StaffUserLoginLive do
  use JaviWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Operações • Entrar")
     |> assign(:error_message, nil)}
  end
end
