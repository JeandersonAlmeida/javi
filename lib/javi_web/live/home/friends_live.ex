defmodule JaviWeb.Home.FriendsLive do
  use JaviWeb, :live_view

  alias Javi.Accounts
  import JaviWeb.Components.BottomNavigation
  import JaviWeb.Components.Header

  @page_size 12

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if is_nil(user) do
      {:ok, push_navigate(socket, to: ~p"/entrar")}
    else
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Javi.PubSub, "friends:#{user.id}")
        Phoenix.PubSub.subscribe(Javi.PubSub, "friend_requests:#{user.id}")
      end

      {friends, total} = Accounts.list_friends(user, 1, @page_size)
      incoming = Accounts.list_incoming_friend_requests(user)
      outgoing = Accounts.list_outgoing_friend_requests(user)

      {:ok,
       assign(socket,
         current_user: user,
         current_page: :friends,
         pending_friend_requests: Accounts.incoming_requests_count(user),
         friends: friends,
         total_friends: total,
         page: 1,
         page_size: @page_size,
         search_query: "",
         search_results: [],
         incoming_requests: incoming,
         outgoing_requests: outgoing
       )}
    end
  end

  @impl true
  def handle_event("search_users", params, socket) do
    q =
      ["q", "value"]
      |> Stream.map(&Map.get(params, &1))
      |> Enum.find(&is_binary/1)
      |> Kernel.||("")
      |> String.trim()
      |> then(fn v ->
        try do
          URI.decode_query(v)
        rescue
          _ -> %{}
        end
        |> Map.get("q", v)
      end)
      |> String.trim()

    results =
      Accounts.search_users_for_friendship(socket.assigns.current_user, q, 20)

    {:noreply, assign(socket, search_query: q, search_results: results)}
  end

  def handle_event("send_request", %{"user_id" => to_user_id}, socket) do
    target = Accounts.get_user!(to_int(to_user_id))

    case Accounts.send_friend_request(socket.assigns.current_user, target) do
      {:ok, _req} ->
        {:noreply,
         socket
         |> put_flash(:info, "Solicitação enviada")
         |> assign(
           :outgoing_requests,
           Accounts.list_outgoing_friend_requests(socket.assigns.current_user)
         )}

      {:error, :already_friends} ->
        {:noreply, put_flash(socket, :info, "Vocês já são amigos")}

      {:error, :cannot_self_request} ->
        {:noreply, put_flash(socket, :error, "Você não pode enviar para si mesmo")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Não foi possível enviar a solicitação")}
    end
  end

  def handle_event("accept_request", %{"request_id" => req_id}, socket) do
    case Accounts.accept_friend_request(socket.assigns.current_user, to_int(req_id)) do
      {:ok, _} ->
        {friends, total} =
          Accounts.list_friends(socket.assigns.current_user, socket.assigns.page, @page_size)

        {:noreply,
         socket
         |> put_flash(:info, "Solicitação aceita")
         |> assign(
           :incoming_requests,
           Accounts.list_incoming_friend_requests(socket.assigns.current_user)
         )
         |> assign(:friends, friends)
         |> assign(:total_friends, total)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Falha ao aceitar solicitação")}
    end
  end

  def handle_event("decline_request", %{"request_id" => req_id}, socket) do
    case Accounts.decline_friend_request(socket.assigns.current_user, to_int(req_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Solicitação recusada")
         |> assign(
           :incoming_requests,
           Accounts.list_incoming_friend_requests(socket.assigns.current_user)
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Falha ao recusar solicitação")}
    end
  end

  def handle_event("cancel_outgoing_request", %{"request_id" => req_id}, socket) do
    case Accounts.cancel_friend_request(socket.assigns.current_user, to_int(req_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Solicitação cancelada")
         |> assign(
           :outgoing_requests,
           Accounts.list_outgoing_friend_requests(socket.assigns.current_user)
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Falha ao cancelar solicitação")}
    end
  end

  def handle_event("remove_friend", %{"user_id" => friend_id}, socket) do
    friend = Accounts.get_user!(to_int(friend_id))

    case Accounts.remove_friend(socket.assigns.current_user, friend) do
      {:ok, _} ->
        {friends, total} =
          Accounts.list_friends(socket.assigns.current_user, socket.assigns.page, @page_size)

        {:noreply,
         socket
         |> put_flash(:info, "Amigo removido")
         |> assign(:friends, friends)
         |> assign(:total_friends, total)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Falha ao remover amigo")}
    end
  end

  def handle_event("prev_page", _params, socket) do
    page = max(socket.assigns.page - 1, 1)
    {friends, _total} = Accounts.list_friends(socket.assigns.current_user, page, @page_size)
    {:noreply, assign(socket, friends: friends, page: page)}
  end

  def handle_event("next_page", _params, socket) do
    max_page =
      div(socket.assigns.total_friends + socket.assigns.page_size - 1, socket.assigns.page_size)

    page = min(socket.assigns.page + 1, max_page)
    {friends, _total} = Accounts.list_friends(socket.assigns.current_user, page, @page_size)
    {:noreply, assign(socket, friends: friends, page: page)}
  end

  @impl true
  def handle_info({:friends_updated}, socket) do
    {friends, total} =
      Accounts.list_friends(socket.assigns.current_user, socket.assigns.page, @page_size)

    {:noreply, assign(socket, friends: friends, total_friends: total)}
  end

  def handle_info({:friend_request_received, _id}, socket) do
    {:noreply,
     assign(socket,
       incoming_requests: Accounts.list_incoming_friend_requests(socket.assigns.current_user)
     )}
  end

  def handle_info({:friend_request_accepted, _recipient_id}, socket) do
    {:noreply,
     assign(socket,
       outgoing_requests: Accounts.list_outgoing_friend_requests(socket.assigns.current_user)
     )}
  end

  defp to_int(v) when is_integer(v), do: v
  defp to_int(v) when is_binary(v), do: String.to_integer(v)
end
