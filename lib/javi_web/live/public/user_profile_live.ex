defmodule JaviWeb.Public.UserProfileLive do
  use JaviWeb, :live_view

  alias Javi.Accounts
  alias Javi.Accounts.User
  import JaviWeb.Components.Header

  @impl true
  def mount(%{"user_nickname" => nickname}, _session, socket) do
    case Accounts.get_user_by_nickname(nickname) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Usuário não encontrado")
         |> push_navigate(to: ~p"/")}

      %User{} = profile_user ->
        lists = Accounts.get_user_lists(profile_user)
        viewer = socket.assigns[:current_user]
        me? = is_map(viewer) and viewer.id == profile_user.id
        visibility = profile_user.profile_visibility || "public"
        allowed_profile = me? or visibility == "public"

        # Friend count for the profile being viewed
        friend_count = Accounts.friend_count(profile_user)

        # Friendship status between viewer and profile_user
        {is_friend, outgoing_request_id, incoming_request_id} =
          cond do
            is_nil(viewer) or me? ->
              {false, nil, nil}

            true ->
              is_friend = Accounts.friends?(viewer, profile_user)

              outgoing_request_id =
                Accounts.list_outgoing_friend_requests(viewer)
                |> Enum.find_value(nil, fn r ->
                  if r.recipient_id == profile_user.id, do: r.id, else: nil
                end)

              incoming_request_id =
                Accounts.list_incoming_friend_requests(viewer)
                |> Enum.find_value(nil, fn r ->
                  if r.sender_id == profile_user.id, do: r.id, else: nil
                end)

              {is_friend, outgoing_request_id, incoming_request_id}
          end

        {:ok,
         socket
         |> assign(:profile_user, profile_user)
         |> assign(:me?, me?)
         |> assign(:allowed_profile, allowed_profile)
         |> assign(:lists, lists)
         |> assign(:friend_count, friend_count)
         |> assign(:is_friend, is_friend)
         |> assign(:outgoing_request_id, outgoing_request_id)
         |> assign(:incoming_request_id, incoming_request_id)
         # Respect fine-grained privacy toggles when profile is viewable
         |> assign(:can_show_watched, allowed_profile && (profile_user.show_watched || false))
         |> assign(:can_show_watching, allowed_profile && (profile_user.show_watching || false))
         |> assign(:can_show_favorites, allowed_profile && (profile_user.show_favorites || false))
         |> assign(:can_show_watchlist, allowed_profile && (profile_user.show_watchlist || false))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative flex size-full min-h-screen flex-col bg-[#141414] overflow-x-hidden">
      <.top_header title={"Perfil de #{@profile_user.display_name || @profile_user.email}"} />

      <div class="flex-1 overflow-y-auto pb-24 pt-20">
        <div class="px-4 lg:px-8 py-6 lg:py-8 max-w-7xl mx-auto">
          <!-- Header card -->
          <div class="bg-[#212121] rounded-lg p-6 lg:p-8 mb-8">
            <div class="flex items-center gap-4">
              <div class="w-16 h-16 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                <span class="text-white text-xl font-bold">
                  {first_letter(@profile_user)}
                </span>
              </div>
              <div class="flex-1">
                <h1 class="text-white text-2xl font-bold">
                  {@profile_user.display_name || "Usuário"}
                </h1>
                <p class="text-gray-400 text-sm">@{@profile_user.nickname}</p>
                <p :if={@profile_user.bio} class="text-gray-400 text-sm">{@profile_user.bio}</p>
                <p class="text-gray-400 text-xs mt-1">
                  Visibilidade: {(@profile_user.profile_visibility || "public") |> String.capitalize()}
                </p>
                <div class="mt-3 flex items-center gap-3 flex-wrap">
                  <div class="bg-[#303030] rounded-lg inline-flex items-center gap-2 px-3 py-2">
                    <span class="text-gray-400 text-xs">Amigos</span>
                    <span class="text-white text-sm font-semibold">{@friend_count}</span>
                  </div>

                  <%= if @me? do %>
                    <.link navigate={~p"/amigos"} class="text-blue-400 text-xs hover:underline">
                      Ver meus amigos
                    </.link>
                  <% else %>
                    <%= cond do %>
                      <% @is_friend -> %>
                        <span class="text-[#ababab] text-xs">Vocês já são amigos</span>
                      <% not is_nil(@outgoing_request_id) -> %>
                        <div class="inline-flex items-center gap-2">
                          <span class="text-[#ababab] text-xs">Solicitação enviada</span>
                          <button
                            phx-click="cancel_outgoing_request"
                            phx-value-request_id={@outgoing_request_id}
                            class="px-3 py-1 bg-[#333] text-white rounded hover:bg-[#444] text-xs"
                          >
                            Cancelar
                          </button>
                        </div>
                      <% not is_nil(@incoming_request_id) -> %>
                        <div class="inline-flex items-center gap-2">
                          <button
                            phx-click="accept_request"
                            phx-value-request_id={@incoming_request_id}
                            class="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 text-xs"
                          >
                            Aceitar
                          </button>
                          <button
                            phx-click="decline_request"
                            phx-value-request_id={@incoming_request_id}
                            class="px-3 py-1 bg-[#333] text-white rounded hover:bg-[#444] text-xs"
                          >
                            Recusar
                          </button>
                        </div>
                      <% true -> %>
                        <button
                          phx-click="send_request"
                          class="px-3 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 text-sm"
                        >
                          Solicitar amizade
                        </button>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Content -->
          <%= if @allowed_profile do %>
            <%= if @can_show_watched do %>
              {render_section("Assistidos", list_by_type(@lists, "watched"))}
            <% end %>

            <%= if @can_show_watching do %>
              {render_section("Assistindo", list_by_type(@lists, "watching"))}
            <% end %>

            <%= if @can_show_favorites do %>
              {render_section("Favoritos", list_by_type(@lists, "favorites"))}
            <% end %>

            <%= if @can_show_watchlist do %>
              {render_section("Quero Assistir", list_by_type(@lists, "want_to_watch"))}
            <% end %>
          <% else %>
            <div class="bg-[#212121] rounded-lg p-6 lg:p-8">
              <h3 class="text-white text-lg lg:text-xl font-semibold mb-2">Perfil privado</h3>
              <p class="text-gray-400 text-sm">Este usuário definiu seu perfil como privado.</p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("send_request", _params, socket) do
    viewer = socket.assigns[:current_user]
    profile_user = socket.assigns.profile_user

    if is_nil(viewer) do
      {:noreply, put_flash(socket, :error, "Faça login para enviar solicitações")}
    else
      case Accounts.send_friend_request(viewer, profile_user) do
        {:ok, req} ->
          {:noreply,
           socket
           |> put_flash(:info, "Solicitação enviada")
           |> assign(:outgoing_request_id, req.id)}

        {:error, :already_friends} ->
          {:noreply, assign(socket, :is_friend, true)}

        {:error, :cannot_self_request} ->
          {:noreply, put_flash(socket, :error, "Você não pode enviar para si mesmo")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Não foi possível enviar a solicitação")}
      end
    end
  end

  def handle_event("cancel_outgoing_request", %{"request_id" => req_id}, socket) do
    viewer = socket.assigns[:current_user]

    case Accounts.cancel_friend_request(viewer, String.to_integer(req_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Solicitação cancelada")
         |> assign(:outgoing_request_id, nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Falha ao cancelar solicitação")}
    end
  end

  def handle_event("accept_request", %{"request_id" => req_id}, socket) do
    viewer = socket.assigns[:current_user]

    case Accounts.accept_friend_request(viewer, String.to_integer(req_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Solicitação aceita")
         |> assign(:incoming_request_id, nil)
         |> assign(:is_friend, true)
         |> assign(:friend_count, socket.assigns.friend_count + 1)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Falha ao aceitar solicitação")}
    end
  end

  def handle_event("decline_request", %{"request_id" => req_id}, socket) do
    viewer = socket.assigns[:current_user]

    case Accounts.decline_friend_request(viewer, String.to_integer(req_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Solicitação recusada")
         |> assign(:incoming_request_id, nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Falha ao recusar solicitação")}
    end
  end

  # ========== Helpers ==========

  defp first_letter(%User{} = user) do
    display = user.display_name
    email = user.email

    cond do
      is_binary(display) and String.trim(display) != "" ->
        String.first(display)

      is_binary(email) and String.trim(email) != "" ->
        String.first(email)

      true ->
        "U"
    end
  end

  defp list_by_type(lists, type), do: Enum.find(lists, &(&1.list_type == type))

  defp take_items(list, n) do
    list
    |> case do
      nil -> []
      l -> l.list_items || []
    end
    |> Enum.take(n)
  end

  defp title_for_item(item), do: item.title

  defp poster_url(%{poster_path: path}) when is_binary(path) and path != "" do
    "https://image.tmdb.org/t/p/w500#{path}"
  end

  defp poster_url(_), do: nil

  defp render_section(_title, nil), do: nil

  defp render_section(title, list) do
    assigns = %{title: title, items: take_items(list, 9)}

    ~H"""
    <div class="bg-[#212121] rounded-lg p-6 lg:p-8 mb-8">
      <h3 class="text-white text-lg lg:text-xl font-semibold mb-4">{@title}</h3>

      <%= if @items == [] do %>
        <p class="text-gray-400 text-sm">Sem itens para mostrar.</p>
      <% else %>
        <div class="grid grid-cols-3 gap-3 lg:gap-4">
          <%= for li <- @items do %>
            <% title_data = title_for_item(li) %>
            <% url = poster_url(title_data) %>
            <div class="relative group">
              <div
                class="w-full bg-center bg-no-repeat aspect-[2/3] bg-cover rounded-xl"
                style={if url, do: "background-image: url(#{url})", else: ""}
                title={title_data.title}
              >
              </div>
              <div class="absolute bottom-2 left-2 text-white text-[11px] bg-black/70 rounded px-2 py-1 truncate max-w-[80%]">
                {title_data.title}
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
