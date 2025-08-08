defmodule JaviWeb.Home.ListDetailLive do
  use JaviWeb, :live_view

  alias Javi.Media
  alias Javi.Media.TMDB.Client, as: TMDBClient
  alias Javi.Accounts
  import JaviWeb.Components.BottomNavigation
  import JaviWeb.Components.Header

  @impl true
  def mount(%{"id" => list_id}, session, socket) do
    # Get current user
    user = get_current_user(session)

    # Get the specific list
    list = get_user_list(user, list_id)

    case list do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/inicio")}

      list ->
        # Sort list items by insertion order (newest first)
        sorted_list_items = Enum.sort_by(list.list_items, & &1.inserted_at, :desc)

        {:ok,
         assign(socket,
           user: user,
           list: list,
           list_items: sorted_list_items,
           current_page: :lists,
           query: "",
           search_results: [],
           show_search: false
         )}
    end
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    case TMDBClient.search_movies(query) do
      {:ok, results} ->
        {:noreply, assign(socket, search_results: results["results"] || [], query: query)}

      {:error, _reason} ->
        {:noreply, assign(socket, search_results: [], query: query)}
    end
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    case TMDBClient.search_movies(query) do
      {:ok, results} ->
        {:noreply, assign(socket, search_results: results["results"] || [], query: query)}

      {:error, _reason} ->
        {:noreply, assign(socket, search_results: [], query: query)}
    end
  end

  @impl true
  def handle_event("toggle_search", _params, socket) do
    {:noreply, assign(socket, show_search: !socket.assigns.show_search)}
  end

  @impl true
  def handle_event("add_to_list", %{"title" => title_data}, socket) do
    user = socket.assigns.user
    list = socket.assigns.list

    case Jason.decode(title_data) do
      {:ok, parsed_title_data} ->
        case add_title_to_list(list, parsed_title_data) do
          {:ok, _list_item} ->
            # Refresh the list items and sort by newest first
            updated_list = get_user_list(user, list.id)
            sorted_list_items = Enum.sort_by(updated_list.list_items, & &1.inserted_at, :desc)
            {:noreply, assign(socket, list_items: sorted_list_items)}

          {:error, _} ->
            {:noreply, socket}
        end

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_from_list", %{"list-item-id" => list_item_id}, socket) do
    user = socket.assigns.user
    list = socket.assigns.list

    parsed_id =
      cond do
        is_integer(list_item_id) ->
          list_item_id

        is_binary(list_item_id) ->
          case Integer.parse(list_item_id) do
            {int_id, _} -> int_id
            :error -> nil
          end

        true ->
          nil
      end

    if is_nil(parsed_id) do
      {:noreply, socket}
    else
      case Accounts.remove_title_from_list(list, parsed_id) do
        {:ok, _} ->
          # Refresh the list items and sort by newest first
          updated_list = get_user_list(user, list.id)
          sorted_list_items = Enum.sort_by(updated_list.list_items, & &1.inserted_at, :desc)
          {:noreply, assign(socket, list_items: sorted_list_items)}

        {:error, _} ->
          {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("add_to_watched", %{"title" => title_data}, socket) do
    case socket.assigns.user do
      nil ->
        {:noreply, socket}

      user ->
        case Jason.decode(title_data) do
          {:ok, parsed_title_data} ->
            case Media.add_title_to_watched_list(user, parsed_title_data) do
              {:ok, _list_item} ->
                {:noreply, socket}

              {:error, _} ->
                {:noreply, socket}
            end

          {:error, _} ->
            {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_event("navigate_to_list", %{"list-id" => list_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/listas/#{list_id}")}
  end

  @impl true
  def handle_event("navigate_to_title", %{"title-id" => title_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/titulos/#{title_id}?referrer=lists")}
  end

  @impl true
  def handle_event("navigate_to_title", %{"title" => title_data}, socket) do
    case Jason.decode(title_data) do
      {:ok, movie_data} ->
        # Create or get the title from database
        case Media.get_or_create_title(movie_data["id"], movie_data["media_type"] || "movie", %{
               title: movie_data["title"] || movie_data["name"],
               original_title: movie_data["original_title"] || movie_data["original_name"],
               overview: movie_data["overview"],
               release_date: parse_date(movie_data["release_date"]),
               first_air_date: parse_date(movie_data["first_air_date"]),
               vote_average: parse_decimal(movie_data["vote_average"]),
               vote_count: movie_data["vote_count"],
               popularity: parse_decimal(movie_data["popularity"]),
               poster_path: movie_data["poster_path"],
               backdrop_path: movie_data["backdrop_path"],
               adult: movie_data["adult"] || false,
               genres: convert_genre_ids_to_strings(movie_data["genre_ids"] || []),
               runtime: movie_data["runtime"],
               episode_run_time: movie_data["episode_run_time"],
               number_of_seasons: movie_data["number_of_seasons"],
               number_of_episodes: movie_data["number_of_episodes"]
             }) do
          {:ok, _title} ->
            # Navigate with referrer parameter
            {:noreply, push_navigate(socket, to: ~p"/titulos/#{movie_data["id"]}?referrer=lists")}

          {:error, _changeset} ->
            {:noreply, socket}
        end

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("go_back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/listas")}
  end

  # Private functions

  defp get_current_user(session) do
    case session["user_token"] do
      nil -> nil
      token -> Accounts.get_user_by_session_token(token)
    end
  end

  defp get_user_list(user, list_id) do
    case user do
      nil -> nil
      user -> Accounts.get_user_list(user, list_id)
    end
  end

  defp add_title_to_list(list, title_data) do
    # First, get or create the title
    case Media.get_or_create_title(title_data["id"], title_data["media_type"] || "movie", %{
           title: title_data["title"] || title_data["name"],
           original_title: title_data["original_title"] || title_data["original_name"],
           overview: title_data["overview"],
           poster_path: title_data["poster_path"],
           release_date: title_data["release_date"] || title_data["first_air_date"],
           vote_average: title_data["vote_average"],
           popularity: title_data["popularity"],
           genres: convert_genre_ids_to_strings(title_data["genre_ids"] || []),
           runtime: title_data["runtime"],
           episode_run_time: title_data["episode_run_time"],
           number_of_seasons: title_data["number_of_seasons"],
           number_of_episodes: title_data["number_of_episodes"]
         }) do
      {:ok, title} ->
        # Add title to the list
        Accounts.add_title_to_list(list, title)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp parse_decimal(nil), do: nil
  defp parse_decimal(value) when is_float(value), do: Decimal.new(Float.to_string(value))
  defp parse_decimal(value) when is_integer(value), do: Decimal.new(value)

  defp parse_decimal(value) when is_binary(value) do
    try do
      Decimal.new(value)
    rescue
      _ -> nil
    end
  end

  defp convert_genre_ids_to_strings(genre_ids) when is_list(genre_ids) do
    genre_ids
    |> Enum.map(&to_string/1)
    |> Enum.filter(&(&1 != nil))
  end

  defp convert_genre_ids_to_strings(_), do: []
end
