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

        {:ok,
         socket
         |> assign(:profile_user, profile_user)
         |> assign(:me?, me?)
         |> assign(:allowed_profile, allowed_profile)
         |> assign(:lists, lists)
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
              <div>
                <h1 class="text-white text-2xl font-bold">
                  {@profile_user.display_name || "Usuário"}
                </h1>
                <p class="text-gray-400 text-sm">@{@profile_user.nickname}</p>
                <p :if={@profile_user.bio} class="text-gray-400 text-sm">{@profile_user.bio}</p>
                <p class="text-gray-400 text-xs mt-1">
                  Visibilidade: {(@profile_user.profile_visibility || "public") |> String.capitalize()}
                </p>
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
