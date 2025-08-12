defmodule JaviWeb.Home.SearchLive do
  use JaviWeb, :live_view

  alias Javi.Media
  alias Javi.Media.TMDB.Client, as: TMDBClient
  import JaviWeb.Components.BottomNavigation
  import JaviWeb.Components.Header
  import JaviWeb.Helpers.GenreHelper

  # Cache timeout in seconds (5 minutes)
  @cache_timeout 300
  @genres_per_page 3
  @titles_per_genre 18
  @max_genres 12
  # 20 seconds timeout for load more operations
  @load_more_timeout 20000

  @impl true
  def mount(_params, session, socket) do
    user = get_current_user(session)

    # Get cached data or fetch fresh data
    cached_data = get_cached_search_data()

    # Get user lists for the modal
    user_lists = get_user_lists(user)

    # Get available genres
    available_genres = get_available_genres()

    # Initialize used titles set with existing section titles to avoid duplicates
    existing_titles =
      []
      |> Enum.concat(cached_data.trending_movies || [])
      |> Enum.concat(cached_data.trending_tv_shows || [])
      |> Enum.concat(cached_data.recent_releases || [])
      |> Enum.concat(cached_data.top_rated || [])

    existing_title_ids =
      existing_titles
      |> Enum.map(fn title -> title["id"] end)
      |> MapSet.new()

    Process.put(:used_title_ids, existing_title_ids)

    # Initialize with first 2 genres
    initial_genres = Enum.take(available_genres, @genres_per_page)
    genre_sections = load_genre_sections(initial_genres)

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
      |> assign(:available_genres, available_genres)
      |> assign(:loaded_genres_count, @genres_per_page)
      |> assign(:is_loading_more, false)
      |> assign(:max_genres, @max_genres)
      |> assign(:genres_per_page, @genres_per_page)
      |> assign(:titles_per_genre, @titles_per_genre)
      |> stream(:genre_sections, genre_sections)

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
  def handle_event("load_more_genres", _params, socket) do
    if socket.assigns.loaded_genres_count < @max_genres and not socket.assigns.is_loading_more do
      # Set loading state
      socket = assign(socket, :is_loading_more, true)

      # Get next batch of genres - load more each time for better experience
      current_count = socket.assigns.loaded_genres_count

      next_genres =
        socket.assigns.available_genres
        |> Enum.slice(current_count, @genres_per_page)

      if next_genres != [] do
        # Load genre sections with error handling and timeout
        try do
          # Add a timeout to the entire operation
          case Process.send_after(self(), {:load_more_timeout, current_count}, @load_more_timeout) do
            timer_ref when is_reference(timer_ref) ->
              # Load genre sections
              case load_genre_sections(next_genres) do
                genre_sections when is_list(genre_sections) and length(genre_sections) > 0 ->
                  # Cancel timeout
                  Process.cancel_timer(timer_ref)

                  # Add to stream
                  socket = stream(socket, :genre_sections, genre_sections, at: -1)

                  # Update counts
                  socket =
                    assign(socket,
                      loaded_genres_count: current_count + @genres_per_page,
                      is_loading_more: false
                    )

                  {:noreply, socket}

                _ ->
                  # Cancel timeout
                  Process.cancel_timer(timer_ref)

                  # Handle case where no genre sections were loaded
                  {:noreply, assign(socket, :is_loading_more, false)}
              end

            _ ->
              {:noreply, assign(socket, :is_loading_more, false)}
          end
        rescue
          _ ->
            # Handle any errors gracefully
            {:noreply, assign(socket, :is_loading_more, false)}
        end
      else
        {:noreply, assign(socket, :is_loading_more, false)}
      end
    else
      {:noreply, socket}
    end
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

  defp get_available_genres do
    # Get movie genres and convert to Portuguese
    case TMDBClient.get_movie_genres() do
      {:ok, %{"genres" => genres}} ->
        genres
        |> Enum.map(fn genre ->
          %{
            id: genre["id"],
            name: translate_genre_id(to_string(genre["id"])),
            original_name: genre["name"]
          }
        end)
        # Shuffle genres to get variety
        |> Enum.shuffle()
        |> Enum.take(@max_genres)

      {:error, _} ->
        # Fallback to basic genres if API fails
        [
          %{id: 28, name: "Ação", original_name: "Action"},
          %{id: 12, name: "Aventura", original_name: "Adventure"},
          %{id: 16, name: "Animação", original_name: "Animation"},
          %{id: 35, name: "Comédia", original_name: "Comedy"},
          %{id: 80, name: "Crime", original_name: "Crime"},
          %{id: 99, name: "Documentário", original_name: "Documentary"},
          %{id: 18, name: "Drama", original_name: "Drama"},
          %{id: 10751, name: "Família", original_name: "Family"},
          %{id: 14, name: "Fantasia", original_name: "Fantasy"},
          %{id: 27, name: "Terror", original_name: "Horror"},
          %{id: 10402, name: "Música", original_name: "Music"},
          %{id: 9648, name: "Mistério", original_name: "Mystery"},
          %{id: 10752, name: "Guerra", original_name: "War"}
        ]
        |> Enum.shuffle()
        |> Enum.take(@max_genres)
    end
  end

  defp load_genre_sections(genres) do
    # Track used title IDs to avoid duplicates across all genre sections
    used_title_ids = Process.get(:used_title_ids) || MapSet.new()

    result =
      genres
      |> Enum.map(fn genre ->
        try do
          titles = fetch_titles_by_genre(genre.id)

          # Filter out titles that have already been used in other genre sections
          available_titles =
            titles
            |> Enum.reject(fn title ->
              title_id = title["id"]
              MapSet.member?(used_title_ids, title_id)
            end)

          # If we don't have enough titles after deduplication, try to fetch more
          available_titles =
            if length(available_titles) < @titles_per_genre do
              additional_titles = fetch_additional_titles_by_genre(genre.id, used_title_ids)
              available_titles ++ additional_titles
            else
              available_titles
            end

          # Limit to the desired number of titles
          final_titles = Enum.take(available_titles, @titles_per_genre)

          # Add the new titles to the used set
          new_title_ids =
            final_titles
            |> Enum.map(fn title -> title["id"] end)
            |> MapSet.new()

          updated_used_ids = MapSet.union(used_title_ids, new_title_ids)
          Process.put(:used_title_ids, updated_used_ids)

          %{
            id: "genre_#{genre.id}",
            genre: genre,
            titles: final_titles,
            loading: false
          }
        rescue
          _ ->
            # Return a minimal genre section if there's an error
            %{
              id: "genre_#{genre.id}",
              genre: genre,
              titles: [],
              loading: false
            }
        end
      end)

    result
  end

  defp fetch_titles_by_genre(genre_id) do
    # Get both popular and recent movies for the genre to balance quality and freshness
    popular_task =
      Task.async(fn ->
        case TMDBClient.get_popular_movies_by_genre(genre_id) do
          {:ok, %{"results" => results}} ->
            results

          {:error, _error} ->
            []
        end
      end)

    recent_task =
      Task.async(fn ->
        case TMDBClient.get_movies_by_genre(genre_id) do
          {:ok, %{"results" => results}} ->
            results

          {:error, _error} ->
            []
        end
      end)

    # 15 second timeout
    popular_results = Task.await(popular_task, 15000)
    # 15 second timeout
    recent_results = Task.await(recent_task, 15000)

    # Combine and deduplicate results
    all_results =
      (popular_results ++ recent_results)
      # Remove duplicates by TMDB ID
      |> Enum.uniq_by(& &1["id"])
      # Filter out inappropriate content
      |> Enum.reject(&is_inappropriate_content?/1)
      # Smart ranking considering both factors
      |> smart_rank_by_rating_and_recency()
      # Fetch more titles initially to account for potential duplicates
      |> Enum.take(@titles_per_genre * 2)
      |> Enum.map(fn title ->
        Map.put(title, "media_type", "movie")
      end)

    all_results
  end

  defp fetch_additional_titles_by_genre(genre_id, _used_title_ids) do
    # Get popular movies for the genre
    popular_task =
      Task.async(fn ->
        case TMDBClient.get_popular_movies_by_genre(genre_id) do
          {:ok, %{"results" => results}} ->
            results

          {:error, _error} ->
            []
        end
      end)

    # Get recent movies for the genre
    recent_task =
      Task.async(fn ->
        case TMDBClient.get_movies_by_genre(genre_id) do
          {:ok, %{"results" => results}} ->
            results

          {:error, _error} ->
            []
        end
      end)

    # 15 second timeout
    popular_results = Task.await(popular_task, 15000)
    # 15 second timeout
    recent_results = Task.await(recent_task, 15000)

    # Combine and deduplicate results
    all_results =
      (popular_results ++ recent_results)
      # Remove duplicates by TMDB ID
      |> Enum.uniq_by(& &1["id"])
      # Filter out inappropriate content
      |> Enum.reject(&is_inappropriate_content?/1)
      # Smart ranking considering both factors
      |> smart_rank_by_rating_and_recency()
      # Fetch more titles initially to account for potential duplicates
      |> Enum.take(@titles_per_genre * 2)
      |> Enum.map(fn title ->
        Map.put(title, "media_type", "movie")
      end)

    all_results
  end

  # Smart ranking that balances rating and recency
  defp smart_rank_by_rating_and_recency(titles) do
    current_year = Date.utc_today().year

    titles
    |> Enum.sort_by(
      fn title ->
        # Get rating and vote count
        vote_average = title["vote_average"] || 0.0
        vote_count = title["vote_count"] || 0

        # Get release year
        release_date = title["release_date"]

        release_year =
          case release_date do
            date when is_binary(date) ->
              case Date.from_iso8601(date) do
                {:ok, parsed_date} -> parsed_date.year
                {:error, _} -> current_year
              end

            _ ->
              current_year
          end

        # Calculate recency score (newer movies get higher score)
        # Base year 1990
        recency_score = max(0, release_year - 1990) * 0.1

        # Calculate rating score with vote count reliability
        rating_score = vote_average * :math.log10(max(vote_count, 1))

        # Calculate final score with balanced weights
        # 70% rating quality, 30% recency
        final_score = rating_score * 0.7 + recency_score * 0.3

        final_score
      end,
      # Sort in descending order (highest scores first)
      :desc
    )
  end

  # Enhanced sorting for other content sections
  defp sort_by_rating_and_popularity(titles) do
    current_year = Date.utc_today().year

    titles
    |> Enum.sort_by(
      fn title ->
        # Get rating and vote count
        vote_average = title["vote_average"] || 0.0
        vote_count = title["vote_count"] || 0
        popularity = title["popularity"] || 0.0

        # Get release year
        release_date = title["release_date"] || title["first_air_date"]

        release_year =
          case release_date do
            date when is_binary(date) ->
              case Date.from_iso8601(date) do
                {:ok, parsed_date} -> parsed_date.year
                {:error, _} -> current_year
              end

            _ ->
              current_year
          end

        # Calculate recency score
        recency_score = max(0, release_year - 1990) * 0.1

        # Calculate rating score
        rating_score = vote_average * :math.log10(max(vote_count, 1))

        # Calculate popularity score
        # Lower weight for popularity
        popularity_score = popularity * 0.05

        # Final score: 60% rating, 25% recency, 15% popularity
        final_score = rating_score * 0.6 + recency_score * 0.25 + popularity_score * 0.15

        final_score
      end,
      :desc
    )
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
      {:ok, results} ->
        (results["results"] || [])
        # Filter out inappropriate content
        |> Enum.reject(&is_inappropriate_content?/1)
        # Sort by rating and popularity
        |> sort_by_rating_and_popularity()

      {:error, _} ->
        []
    end
  end

  defp fetch_trending_tv_shows do
    case TMDBClient.get_trending_tv("day") do
      {:ok, results} ->
        (results["results"] || [])
        # Filter out inappropriate content
        |> Enum.reject(&is_inappropriate_content?/1)
        # Sort by rating and popularity
        |> sort_by_rating_and_popularity()

      {:error, _} ->
        []
    end
  end

  defp fetch_recent_releases do
    case TMDBClient.get_upcoming_movies() do
      {:ok, results} ->
        (results["results"] || [])
        # Filter out inappropriate content
        |> Enum.reject(&is_inappropriate_content?/1)
        # Sort by rating and popularity
        |> sort_by_rating_and_popularity()

      {:error, _} ->
        []
    end
  end

  defp fetch_top_rated do
    # Fetch top rated movies and popular TV shows (since there's no top_rated_tv)
    movie_task =
      Task.async(fn ->
        case TMDBClient.get_top_rated_movies() do
          {:ok, results} ->
            (results["results"] || [])
            # Filter out inappropriate content
            |> Enum.reject(&is_inappropriate_content?/1)
            # Sort by rating and popularity
            |> sort_by_rating_and_popularity()

          {:error, _} ->
            []
        end
      end)

    tv_task =
      Task.async(fn ->
        case TMDBClient.get_trending_tv("week") do
          {:ok, results} ->
            (results["results"] || [])
            # Filter out inappropriate content
            |> Enum.reject(&is_inappropriate_content?/1)
            # Sort by rating and popularity
            |> sort_by_rating_and_popularity()

          {:error, _} ->
            []
        end
      end)

    movies = Task.await(movie_task)
    tv_shows = Task.await(tv_task)

    # Combine and shuffle results, but keep the best ones first
    (movies ++ tv_shows)
    |> sort_by_rating_and_popularity()
  end

  defp perform_multi_search(query) do
    case TMDBClient.search_movies(query) do
      {:ok, movie_results} ->
        case TMDBClient.search_tv(query) do
          {:ok, tv_results} ->
            results =
              ((movie_results["results"] || []) ++ (tv_results["results"] || []))
              # Filter out inappropriate content
              |> Enum.reject(&is_inappropriate_content?/1)
              # Sort by rating and popularity
              |> sort_by_rating_and_popularity()

            {:ok, results}

          {:error, _} ->
            results =
              (movie_results["results"] || [])
              # Filter out inappropriate content
              |> Enum.reject(&is_inappropriate_content?/1)
              # Sort by rating and popularity
              |> sort_by_rating_and_popularity()

            {:ok, results}
        end

      {:error, _} ->
        case TMDBClient.search_tv(query) do
          {:ok, tv_results} ->
            results =
              (tv_results["results"] || [])
              # Filter out inappropriate content
              |> Enum.reject(&is_inappropriate_content?/1)
              # Sort by rating and popularity
              |> sort_by_rating_and_popularity()

            {:ok, results}

          {:error, _} ->
            {:error, :search_failed}
        end
    end
  end

  # Helper function to determine if content is inappropriate
  defp is_inappropriate_content?(title) do
    # Check if content is marked as adult
    if title["adult"] == true do
      true
    else
      # Check for age ratings that indicate 18+ content
      # Common age rating fields in TMDB responses
      age_rating = title["certification"] || title["rating"] || title["age_rating"]

      case age_rating do
        rating when is_binary(rating) ->
          # Check for various 18+ rating formats
          rating = String.upcase(rating)
          rating in ["18", "18+", "R", "NC-17", "X", "A", "18A", "R18", "R18+"]

        _ ->
          # If no age rating found, check other indicators
          # Look for content warnings or mature themes
          has_mature_content?(title)
      end
    end
  end

  # Check for mature content indicators
  defp has_mature_content?(title) do
    # Check for mature themes in overview or keywords
    overview = String.downcase(title["overview"] || "")

    # Keywords that might indicate mature content
    mature_keywords = [
      "sexual",
      "nudity",
      "explicit",
      "mature",
      "adult content",
      "sexual content",
      "sexual themes",
      "mature themes"
    ]

    # Check if any mature keywords are in the overview
    Enum.any?(mature_keywords, &String.contains?(overview, &1))
  end

  @impl true
  def handle_info({:load_more_timeout, _count}, socket) do
    # Handle timeout for load more operation
    {:noreply, assign(socket, :is_loading_more, false)}
  end
end
