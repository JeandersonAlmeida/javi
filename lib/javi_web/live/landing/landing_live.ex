defmodule JaviWeb.Landing.LandingLive do
  use JaviWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Javi - Seu Companheiro de Entretenimento")}
  end

  @impl true
  def handle_event("navigate_to_register", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/cadastrar")}
  end

  @impl true
  def handle_event("navigate_to_login", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/entrar")}
  end
end
