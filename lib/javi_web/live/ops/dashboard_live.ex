defmodule JaviWeb.Ops.DashboardLive do
  use JaviWeb, :live_view

  alias Javi.Accounts
  alias Javi.Accounts.{User, List}
  alias Javi.Repo

  import JaviWeb.Components.Header

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to user-related events once the LiveView is connected
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Javi.PubSub, "accounts:users")
    end

    users_count = Repo.aggregate(User, :count, :id)
    lists_count = Repo.aggregate(List, :count, :id)

    recent_users = Accounts.list_users_with_stats(20)

    {:ok,
     socket
     |> assign(:users_count, users_count)
     |> assign(:lists_count, lists_count)
     |> assign(:recent_users, recent_users)}
  end

  @impl true
  def handle_info({:user_created, _user_id}, socket) do
    users_count = Repo.aggregate(User, :count, :id)
    lists_count = Repo.aggregate(List, :count, :id)

    recent_users = Accounts.list_users_with_stats(20)

    {:noreply,
     socket
     |> assign(:users_count, users_count)
     |> assign(:lists_count, lists_count)
     |> assign(:recent_users, recent_users)}
  end
end
