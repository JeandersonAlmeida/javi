defmodule JaviWeb.Home.SearchLive do
  use JaviWeb, :live_view

  alias Javi.Media
  alias Javi.Media.TMDB.Client, as: TMDBClient
  import JaviWeb.Components.BottomNavigation
  import JaviWeb.Components.Header

  # Cache timeout in seconds (5 minutes)
  @cache_timeout 300

  @impl true
  def mount(_params, session, socket) do
    user = get_current_user(session)

    # Get cached data or fetch fresh data
    cached_data = get_cached_search_data()

    # Get user lists for the modal
    user_lists = get_user_lists(user)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:query, "")
      |> assign(:search_results, [])
      |> assign(:trending_movies, cached_data.trending_movies)
      |> assign(:trending_tv_shows, cached_data.trending_tv_shows)
      |> assign(:recent_releases, cached_data.recent_releases)
      |> assign(:top_rated, cached_data.top_rated)
      |> assign(:current_page, :search)
      |> assign(:show_modal, false)
      |> assign(:selected_title, nil)
      |> assign(:user_lists, user_lists)
      |> assign(:selected_lists, [])

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    case perform_multi_search(query) do
      {:ok, results} ->
        {:noreply, assign(socket, search_results: results, query: query)}

      {:error, _} ->
        {:noreply, assign(socket, search_results: [], query: query)}
    end
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    case perform_multi_search(query) do
      {:ok, results} ->
        {:noreply, assign(socket, search_results: results, query: query)}

      {:error, _} ->
        {:noreply, assign(socket, search_results: [], query: query)}
    end
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, assign(socket, search_results: [], query: "")}
  end

  @impl true
  def handle_event("show_add_to_lists_modal", %{"title" => title_data}, socket) do
    case Jason.decode(title_data) do
      {:ok, parsed_title_data} ->
        {:noreply,
         socket
         |> assign(:show_modal, true)
         |> assign(:selected_title, parsed_title_data)
         |> assign(:selected_lists, [])}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, false)
     |> assign(:selected_title, nil)
     |> assign(:selected_lists, [])}
  end

  @impl true
  def handle_event("toggle_list_selection", %{"list_id" => list_id}, socket) do
    selected_lists = socket.assigns.selected_lists

    new_selected_lists =
      if list_id in selected_lists do
        List.delete(selected_lists, list_id)
      else
        [list_id | selected_lists]
      end

    {:noreply, assign(socket, :selected_lists, new_selected_lists)}
  end

  @impl true
  def handle_event("add_to_selected_lists", _params, socket) do
    user = socket.assigns.user
    selected_title = socket.assigns.selected_title
    selected_lists = socket.assigns.selected_lists

    case user do
      nil ->
        {:noreply, socket}

      _user ->
        # Add title to each selected list
        results =
          Enum.map(selected_lists, fn list_id ->
            list = Enum.find(socket.assigns.user_lists, &(&1.id == String.to_integer(list_id)))

            if list do
              # First create or get the title
              case Media.get_or_create_title(
                     selected_title["id"],
                     selected_title["media_type"] || "movie",
                     %{
                       title: selected_title["title"] || selected_title["name"],
                       original_title:
                         selected_title["original_title"] || selected_title["original_name"],
                       overview: selected_title["overview"],
                       release_date: parse_date(selected_title["release_date"]),
                       first_air_date: parse_date(selected_title["first_air_date"]),
                       vote_average: parse_decimal(selected_title["vote_average"]),
                       vote_count: selected_title["vote_count"],
                       popularity: parse_decimal(selected_title["popularity"]),
                       poster_path: selected_title["poster_path"],
                       backdrop_path: selected_title["backdrop_path"],
                       adult: selected_title["adult"] || false,
                       genres: convert_genre_ids_to_strings(selected_title["genre_ids"] || []),
                       runtime: selected_title["runtime"],
                       episode_run_time: selected_title["episode_run_time"],
                       number_of_seasons: selected_title["number_of_seasons"],
                       number_of_episodes: selected_title["number_of_episodes"]
                     }
                   ) do
                {:ok, title} ->
                  # Then add to the list
                  case Javi.Accounts.add_title_to_list(list, title) do
                    {:ok, _list_item} -> {:ok, list.name}
                    {:error, _} -> {:error, list.name}
                  end

                {:error, _} ->
                  {:error, list.name}
              end
            else
              {:error, "Lista não encontrada"}
            end
          end)

        # Count successful and failed additions
        successful = Enum.count(results, fn {status, _} -> status == :ok end)
        failed = Enum.count(results, fn {status, _} -> status == :error end)

        # Create feedback message
        message =
          cond do
            successful > 0 and failed == 0 ->
              "Título adicionado com sucesso a #{successful} lista(s)!"

            successful > 0 and failed > 0 ->
              "Título adicionado a #{successful} lista(s), #{failed} falha(s)."

            failed > 0 ->
              "Erro ao adicionar título às listas."

            true ->
              "Nenhuma lista selecionada."
          end

        # Refresh user lists to get updated counts
        updated_user_lists = get_user_lists(user)

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> assign(:show_modal, false)
         |> assign(:selected_title, nil)
         |> assign(:selected_lists, [])
         |> assign(:user_lists, updated_user_lists)}
    end
  end

  @impl true
  def handle_event("add_to_watched", %{"title" => title_data}, socket) do
    user = socket.assigns.user

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

  @impl true
  def handle_event("go_back", _params, socket) do
    {:noreply, push_navigate(socket, to: "/home")}
  end

  @impl true
  def handle_event("refresh_cache", _params, socket) do
    # Force refresh the cache
    fresh_data = fetch_search_data()
    cache_data(fresh_data)

    {:noreply,
     socket
     |> assign(:trending_movies, fresh_data.trending_movies)
     |> assign(:trending_tv_shows, fresh_data.trending_tv_shows)
     |> assign(:recent_releases, fresh_data.recent_releases)
     |> assign(:top_rated, fresh_data.top_rated)}
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
          {:ok, title} ->
            # Navigate using the database ID
            {:noreply, push_navigate(socket, to: ~p"/titulos/#{title.id}?referrer=search")}

          {:error, _changeset} ->
            {:noreply, socket}
        end

      {:error, _error} ->
        {:noreply, socket}
    end
  end

  # Private functions

  defp get_current_user(session) do
    case session["user_token"] do
      nil -> nil
      token -> Javi.Accounts.get_user_by_session_token(token)
    end
  end

  defp get_user_lists(user) do
    case user do
      nil -> []
      user -> Javi.Accounts.get_user_lists(user)
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

  # Cache management functions

  defp get_cached_search_data do
    case Process.get(:search_cache) do
      nil ->
        # No cache exists, fetch fresh data
        fresh_data = fetch_search_data()
        cache_data(fresh_data)
        fresh_data

      {data, timestamp} ->
        # Check if cache is still valid
        if System.system_time(:second) - timestamp < @cache_timeout do
          data
        else
          # Cache expired, fetch fresh data
          fresh_data = fetch_search_data()
          cache_data(fresh_data)
          fresh_data
        end
    end
  end

  defp fetch_search_data do
    # Fetch all data in parallel for better performance
    [
      trending_movies_task,
      trending_tv_shows_task,
      recent_releases_task,
      top_rated_task
    ] = [
      Task.async(fn -> fetch_trending_movies() end),
      Task.async(fn -> fetch_trending_tv_shows() end),
      Task.async(fn -> fetch_recent_releases() end),
      Task.async(fn -> fetch_top_rated() end)
    ]

    %{
      trending_movies: Task.await(trending_movies_task),
      trending_tv_shows: Task.await(trending_tv_shows_task),
      recent_releases: Task.await(recent_releases_task),
      top_rated: Task.await(top_rated_task)
    }
  end

  defp cache_data(data) do
    Process.put(:search_cache, {data, System.system_time(:second)})
  end

  # Individual fetch functions

  defp fetch_trending_movies do
    case TMDBClient.get_trending_movies("day") do
      {:ok, results} -> results["results"] || []
      {:error, _} -> []
    end
  end

  defp fetch_trending_tv_shows do
    case TMDBClient.get_trending_tv("day") do
      {:ok, results} -> results["results"] || []
      {:error, _} -> []
    end
  end

  defp fetch_recent_releases do
    case TMDBClient.get_upcoming_movies() do
      {:ok, results} -> results["results"] || []
      {:error, _} -> []
    end
  end

  defp fetch_top_rated do
    # Fetch top rated movies and popular TV shows (since there's no top_rated_tv)
    movie_task =
      Task.async(fn ->
        case TMDBClient.get_top_rated_movies() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    tv_task =
      Task.async(fn ->
        case TMDBClient.get_trending_tv("week") do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    movies = Task.await(movie_task)
    tv_shows = Task.await(tv_task)

    # Combine and shuffle results
    (movies ++ tv_shows)
    |> Enum.shuffle()
  end

  defp perform_multi_search(query) do
    case TMDBClient.search_movies(query) do
      {:ok, movie_results} ->
        case TMDBClient.search_tv(query) do
          {:ok, tv_results} ->
            {:ok, (movie_results["results"] || []) ++ (tv_results["results"] || [])}

          {:error, _} ->
            {:ok, movie_results["results"] || []}
        end

      {:error, _} ->
        case TMDBClient.search_tv(query) do
          {:ok, tv_results} ->
            {:ok, tv_results["results"] || []}

          {:error, _} ->
            {:error, :search_failed}
        end
    end
  end
end
