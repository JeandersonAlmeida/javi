defmodule JaviWeb.Home.SectionTitlesLive do
  use JaviWeb, :live_view

  alias Javi.Media
  alias Javi.Media.TMDB.Client, as: TMDBClient
  import JaviWeb.Components.BottomNavigation
  import JaviWeb.Components.Header
  import JaviWeb.Helpers.GenreHelper

  @impl true
  def mount(_params, session, socket) do
    user = get_current_user(session)
    user_lists = get_user_lists(user)

    # Initialize with default values, will be updated in handle_params
    socket =
      socket
      |> assign(:user, user)
      |> assign(:section, "trending_movies")
      |> assign(:section_id, "1")
      |> assign(:section_data, [])
      |> assign(:section_title, "")
      |> assign(:section_description, "")
      |> assign(:current_page, :search)
      |> assign(:show_modal, false)
      |> assign(:selected_title, nil)
      |> assign(:user_lists, user_lists)
      |> assign(:selected_lists, [])
      |> assign(:page, 1)
      |> assign(:per_page, 30)
      |> assign(:has_more, false)
      |> assign(:last_load_count, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, url, socket) do
    # Handle both old and new route formats
    {section, section_id} = extract_section_params(params)

    # If no params, try to determine from URL path
    {section, section_id} =
      if section == "trending_movies" and section_id == "1" do
        get_section_from_path(url)
      else
        {section, section_id}
      end

    # Get user lists for filtering
    user_lists = socket.assigns.user_lists || []

    # Get section data based on section type, passing user lists for filtering
    {section_data, section_title, section_description} =
      get_section_data(section, section_id, user_lists)

    socket =
      socket
      |> assign(:section, section)
      |> assign(:section_id, section_id)
      |> assign(:section_data, section_data)
      |> assign(:section_title, section_title)
      |> assign(:section_description, section_description)
      |> assign(:has_more, should_show_load_more?(section, section_data))

    {:noreply, socket}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    section = socket.assigns.section

    # Don't allow load more for genres since we fetch comprehensive coverage initially
    if section == "genre" do
      {:noreply, socket}
    else
      current_page = socket.assigns.page
      section_id = socket.assigns.section_id
      current_titles = socket.assigns.section_data

      # Load more titles for the section, passing current titles to avoid duplicates
      case load_more_titles(section, section_id, current_page + 1, current_titles) do
        {:ok, new_titles} ->
          if length(new_titles) > 0 do
            # Combine existing and new titles
            updated_section_data = current_titles ++ new_titles

            {:noreply,
             socket
             |> assign(:section_data, updated_section_data)
             |> assign(:page, current_page + 1)
             |> assign(:has_more, length(new_titles) >= socket.assigns.per_page)
             |> assign(:last_load_count, length(new_titles))}
          else
            {:noreply, assign(socket, :has_more, false)}
          end

        _ ->
          {:noreply, socket}
      end
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
            {:noreply, push_navigate(socket, to: ~p"/titulos/#{title.id}?referrer=section")}

          {:error, _changeset} ->
            {:noreply, socket}
        end

      {:error, _error} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("go_back", _params, socket) do
    {:noreply, push_navigate(socket, to: "/pesquisar")}
  end

  # Private functions

  defp extract_section_params(params) do
    cond do
      # New SEO-friendly routes
      Map.has_key?(params, "genre_name") and Map.has_key?(params, "genre_id") ->
        {"genre", %{"genre_name" => params["genre_name"], "genre_id" => params["genre_id"]}}

      # Legacy routes
      Map.has_key?(params, "section") and Map.has_key?(params, "section_id") ->
        {params["section"], params["section_id"]}

      # New SEO-friendly routes without params (need to check current path)
      true ->
        # For now, default to trending movies
        # In a real implementation, you might want to use a different approach
        {"trending_movies", "1"}
    end
  end

  # Helper function to determine section from route path
  defp get_section_from_path(path) do
    cond do
      String.contains?(path, "/filmes-em-alta") -> {"trending_movies", "1"}
      String.contains?(path, "/series-populares") -> {"trending_tv", "1"}
      String.contains?(path, "/lancamentos-recentes") -> {"recent_releases", "1"}
      String.contains?(path, "/melhores-avaliados") -> {"top_rated", "1"}
      true -> {"trending_movies", "1"}
    end
  end

  # Helper function to get proper Portuguese genre names
  defp get_proper_genre_name(url_name) do
    genre_mapping = %{
      "acao" => "Ação",
      "aventura" => "Aventura",
      "animacao" => "Animação",
      "comedia" => "Comédia",
      "crime" => "Crime",
      "documentario" => "Documentário",
      "drama" => "Drama",
      "familia" => "Família",
      "fantasia" => "Fantasia",
      "ficcao-cientifica" => "Ficção Científica",
      "historia" => "História",
      "terror" => "Terror",
      "musica" => "Música",
      "misterio" => "Mistério",
      "romance" => "Romance",
      "suspense" => "Suspense",
      "guerra" => "Guerra",
      "western" => "Western"
    }

    Map.get(
      genre_mapping,
      url_name,
      url_name
      |> String.replace("-", " ")
      |> String.capitalize()
    )
  end

  # Helper function to filter out titles already in user lists
  defp filter_titles_not_in_lists(titles, user_lists) do
    case user_lists do
      [] ->
        titles

      _ ->
        # Get all title IDs that are already in user lists
        existing_title_ids =
          user_lists
          |> Enum.flat_map(fn list ->
            list.list_items || []
          end)
          |> Enum.map(fn item ->
            item.title.tmdb_id
          end)
          |> MapSet.new()

        # Filter out titles that are already in lists
        titles
        |> Enum.reject(fn title ->
          MapSet.member?(existing_title_ids, title["id"])
        end)
    end
  end

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

  # Define the function signature
  defp get_section_data(section, section_id, user_lists)

  defp get_section_data("trending_movies", _section_id, user_lists) do
    # Fetch from multiple sources to get comprehensive coverage
    trending_day_task =
      Task.async(fn ->
        case TMDBClient.get_trending_movies("day") do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    trending_week_task =
      Task.async(fn ->
        case TMDBClient.get_trending_movies("week") do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    popular_movies_task =
      Task.async(fn ->
        case TMDBClient.get_popular_movies() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    trending_day = Task.await(trending_day_task)
    trending_week = Task.await(trending_week_task)
    popular_movies = Task.await(popular_movies_task)

    # Combine all results and deduplicate
    all_titles =
      (trending_day ++ trending_week ++ popular_movies)
      |> Enum.uniq_by(& &1["id"])
      |> Enum.reject(&is_inappropriate_content?/1)
      |> Enum.reject(&has_no_poster?/1)
      |> sort_by_rating_and_popularity()
      |> filter_titles_not_in_lists(user_lists)

    {all_titles, "Filmes em Alta", "Os filmes mais populares do momento"}
  end

  defp get_section_data("trending_tv", _section_id, user_lists) do
    # Fetch from multiple sources to get comprehensive coverage
    trending_day_task =
      Task.async(fn ->
        case TMDBClient.get_trending_tv("day") do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    trending_week_task =
      Task.async(fn ->
        case TMDBClient.get_trending_tv("week") do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    trending_day = Task.await(trending_day_task)
    trending_week = Task.await(trending_week_task)

    # Combine all results and deduplicate
    all_titles =
      (trending_day ++ trending_week)
      |> Enum.uniq_by(& &1["id"])
      |> Enum.reject(&is_inappropriate_content?/1)
      |> Enum.reject(&has_no_poster?/1)
      |> sort_by_rating_and_popularity()
      |> filter_titles_not_in_lists(user_lists)

    {all_titles, "Séries Populares", "As séries mais populares do momento"}
  end

  defp get_section_data("recent_releases", _section_id, user_lists) do
    # Fetch from multiple sources to get comprehensive coverage
    upcoming_movies_task =
      Task.async(fn ->
        case TMDBClient.get_upcoming_movies() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    now_playing_task =
      Task.async(fn ->
        case TMDBClient.get_now_playing_movies() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    upcoming_movies = Task.await(upcoming_movies_task)
    now_playing = Task.await(now_playing_task)

    # Combine all results and deduplicate
    all_titles =
      (upcoming_movies ++ now_playing)
      |> Enum.uniq_by(& &1["id"])
      |> Enum.reject(&is_inappropriate_content?/1)
      |> Enum.reject(&has_no_poster?/1)
      |> sort_by_rating_and_popularity()
      |> filter_titles_not_in_lists(user_lists)

    {all_titles, "Lançamentos Recentes", "Os filmes mais recentes e próximos lançamentos"}
  end

  defp get_section_data("top_rated", _section_id, user_lists) do
    # Get top rated movies and popular TV shows from multiple sources
    top_rated_movies_task =
      Task.async(fn ->
        case TMDBClient.get_top_rated_movies() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    top_rated_tv_task =
      Task.async(fn ->
        case TMDBClient.get_top_rated_tv() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    popular_tv_task =
      Task.async(fn ->
        case TMDBClient.get_popular_tv() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)

    top_rated_movies = Task.await(top_rated_movies_task)
    top_rated_tv = Task.await(top_rated_tv_task)
    popular_tv = Task.await(popular_tv_task)

    # Combine all results and deduplicate
    all_titles =
      (top_rated_movies ++ top_rated_tv ++ popular_tv)
      |> Enum.uniq_by(& &1["id"])
      |> Enum.reject(&is_inappropriate_content?/1)
      |> Enum.reject(&has_no_poster?/1)
      |> sort_by_rating_and_popularity()
      |> filter_titles_not_in_lists(user_lists)

    {all_titles, "Melhores Avaliados", "Os títulos com as melhores avaliações"}
  end

  # Override for genre with name from URL
  defp get_section_data(
         "genre",
         %{"genre_name" => genre_name, "genre_id" => genre_id},
         user_lists
       ) do
    genre_id = String.to_integer(genre_id)

    # Convert URL-friendly name back to readable name with proper Portuguese translations
    readable_genre_name = get_proper_genre_name(genre_name)

    # Get titles for the genre
    titles =
      fetch_titles_by_genre(genre_id)
      |> filter_titles_not_in_lists(user_lists)

    {titles, readable_genre_name, "Títulos do gênero #{readable_genre_name}"}
  end

  defp get_section_data("genre", genre_id, user_lists) do
    genre_id = String.to_integer(genre_id)

    # Get genre name
    genre_name =
      case TMDBClient.get_movie_genres() do
        {:ok, %{"genres" => genres}} ->
          genre = Enum.find(genres, &(&1["id"] == genre_id))
          if genre, do: translate_genre_id(to_string(genre["id"])), else: "Gênero"

        {:error, _} ->
          "Gênero"
      end

    # Get titles for the genre
    titles =
      fetch_titles_by_genre(genre_id)
      |> filter_titles_not_in_lists(user_lists)

    {titles, genre_name, "Títulos do gênero #{genre_name}"}
  end

  defp get_section_data(_section, _section_id, _user_lists) do
    {[], "Seção", "Títulos da seção"}
  end

  defp load_more_titles("trending_movies", _section_id, page, current_titles) do
    # Fetch from multiple sources with pagination
    tasks = [
      Task.async(fn ->
        case TMDBClient.get_trending_movies("day") do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end),
      Task.async(fn ->
        case TMDBClient.get_trending_movies("week") do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end),
      Task.async(fn ->
        case TMDBClient.get_popular_movies() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)
    ]

    all_results = Task.await_many(tasks, 30000)

    # Get current title IDs to avoid duplicates
    current_title_ids = MapSet.new(Enum.map(current_titles, & &1["id"]))

    titles =
      all_results
      |> List.flatten()
      |> Enum.uniq_by(& &1["id"])
      |> Enum.reject(&is_inappropriate_content?/1)
      |> Enum.reject(&has_no_poster?/1)
      |> Enum.reject(fn title -> MapSet.member?(current_title_ids, title["id"]) end)
      |> sort_by_rating_and_popularity()
      |> Enum.slice((page - 1) * 30, 30)

    {:ok, titles}
  end

  defp load_more_titles("trending_tv", _section_id, page, current_titles) do
    # Fetch from multiple sources with pagination
    tasks = [
      Task.async(fn ->
        case TMDBClient.get_trending_tv("day") do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end),
      Task.async(fn ->
        case TMDBClient.get_trending_tv("week") do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)
    ]

    all_results = Task.await_many(tasks, 30000)

    # Get current title IDs to avoid duplicates
    current_title_ids = MapSet.new(Enum.map(current_titles, & &1["id"]))

    titles =
      all_results
      |> List.flatten()
      |> Enum.uniq_by(& &1["id"])
      |> Enum.reject(&is_inappropriate_content?/1)
      |> Enum.reject(&has_no_poster?/1)
      |> Enum.reject(fn title -> MapSet.member?(current_title_ids, title["id"]) end)
      |> sort_by_rating_and_popularity()
      |> Enum.slice((page - 1) * 30, 30)

    {:ok, titles}
  end

  defp load_more_titles("recent_releases", _section_id, page, current_titles) do
    # Fetch from multiple sources with pagination
    tasks = [
      Task.async(fn ->
        case TMDBClient.get_upcoming_movies() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end),
      Task.async(fn ->
        case TMDBClient.get_now_playing_movies() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)
    ]

    all_results = Task.await_many(tasks, 30000)

    # Get current title IDs to avoid duplicates
    current_title_ids = MapSet.new(Enum.map(current_titles, & &1["id"]))

    titles =
      all_results
      |> List.flatten()
      |> Enum.uniq_by(& &1["id"])
      |> Enum.reject(&is_inappropriate_content?/1)
      |> Enum.reject(&has_no_poster?/1)
      |> Enum.reject(fn title -> MapSet.member?(current_title_ids, title["id"]) end)
      |> sort_by_rating_and_popularity()
      |> Enum.slice((page - 1) * 30, 30)

    {:ok, titles}
  end

  defp load_more_titles("top_rated", _section_id, page, current_titles) do
    # Fetch from multiple sources with pagination
    tasks = [
      Task.async(fn ->
        case TMDBClient.get_top_rated_movies() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end),
      Task.async(fn ->
        case TMDBClient.get_top_rated_tv() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end),
      Task.async(fn ->
        case TMDBClient.get_popular_tv() do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)
    ]

    all_results = Task.await_many(tasks, 30000)

    # Get current title IDs to avoid duplicates
    current_title_ids = MapSet.new(Enum.map(current_titles, & &1["id"]))

    titles =
      all_results
      |> List.flatten()
      |> Enum.uniq_by(& &1["id"])
      |> Enum.reject(&is_inappropriate_content?/1)
      |> Enum.reject(&has_no_poster?/1)
      |> Enum.reject(fn title -> MapSet.member?(current_title_ids, title["id"]) end)
      |> sort_by_rating_and_popularity()
      |> Enum.slice((page - 1) * 30, 30)

    {:ok, titles}
  end

  defp load_more_titles("genre", section_id, page, current_titles) do
    # Handle both map and string section_id for genres
    genre_id =
      case section_id do
        %{"genre_id" => id} -> String.to_integer(id)
        id when is_binary(id) -> String.to_integer(id)
        _ -> 0
      end

    # Fetch multiple pages for comprehensive coverage
    tasks = [
      Task.async(fn ->
        case TMDBClient.get_popular_movies_by_genre(genre_id, page) do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end),
      Task.async(fn ->
        case TMDBClient.get_popular_movies_by_genre(genre_id, page + 1) do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end),
      Task.async(fn ->
        case TMDBClient.get_popular_movies_by_genre(genre_id, page + 2) do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end),
      Task.async(fn ->
        case TMDBClient.get_movies_by_genre(genre_id, page) do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end),
      Task.async(fn ->
        case TMDBClient.get_movies_by_genre(genre_id, page + 1) do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end),
      Task.async(fn ->
        case TMDBClient.get_movies_by_genre(genre_id, page + 2) do
          {:ok, results} -> results["results"] || []
          {:error, _} -> []
        end
      end)
    ]

    all_results = Task.await_many(tasks, 30000)

    # Get current title IDs to avoid duplicates
    current_title_ids = MapSet.new(Enum.map(current_titles, & &1["id"]))

    titles =
      all_results
      |> List.flatten()
      |> Enum.uniq_by(& &1["id"])
      |> Enum.reject(&is_inappropriate_content?/1)
      |> Enum.reject(&has_no_poster?/1)
      |> Enum.reject(fn title -> MapSet.member?(current_title_ids, title["id"]) end)
      |> Enum.map(fn title -> Map.put(title, "media_type", "movie") end)

    {:ok, titles}
  end

  defp fetch_titles_by_genre(genre_id) do
    # Get titles from multiple pages and sources for comprehensive coverage
    tasks = [
      # Popular movies by genre - multiple pages (more pages for better coverage)
      Task.async(fn -> fetch_genre_page(genre_id, 1, "popular") end),
      Task.async(fn -> fetch_genre_page(genre_id, 2, "popular") end),
      Task.async(fn -> fetch_genre_page(genre_id, 3, "popular") end),
      Task.async(fn -> fetch_genre_page(genre_id, 4, "popular") end),
      Task.async(fn -> fetch_genre_page(genre_id, 5, "popular") end),
      Task.async(fn -> fetch_genre_page(genre_id, 6, "popular") end),
      Task.async(fn -> fetch_genre_page(genre_id, 7, "popular") end),
      # Recent movies by genre - multiple pages
      Task.async(fn -> fetch_genre_page(genre_id, 1, "recent") end),
      Task.async(fn -> fetch_genre_page(genre_id, 2, "recent") end),
      Task.async(fn -> fetch_genre_page(genre_id, 3, "recent") end),
      Task.async(fn -> fetch_genre_page(genre_id, 4, "recent") end),
      Task.async(fn -> fetch_genre_page(genre_id, 5, "recent") end),
      Task.async(fn -> fetch_genre_page(genre_id, 6, "recent") end)
    ]

    # Wait for all tasks to complete
    # 30 second timeout
    all_results = Task.await_many(tasks, 30000)

    # Combine all results and deduplicate
    all_results
    |> List.flatten()
    |> Enum.uniq_by(& &1["id"])
    |> Enum.reject(&is_inappropriate_content?/1)
    |> Enum.reject(&has_no_poster?/1)
    |> smart_rank_by_rating_and_recency()
    |> Enum.map(fn title -> Map.put(title, "media_type", "movie") end)
  end

  defp fetch_genre_page(genre_id, page, type) do
    case type do
      "popular" ->
        case TMDBClient.get_popular_movies_by_genre(genre_id, page) do
          {:ok, %{"results" => results}} -> results
          {:error, _} -> []
        end

      "recent" ->
        case TMDBClient.get_movies_by_genre(genre_id, page) do
          {:ok, %{"results" => results}} -> results
          {:error, _} -> []
        end

      _ ->
        []
    end
  end

  # Smart ranking that balances rating and recency
  defp smart_rank_by_rating_and_recency(titles) do
    current_year = Date.utc_today().year

    titles
    |> Enum.sort_by(
      fn title ->
        vote_average = title["vote_average"] || 0.0
        vote_count = title["vote_count"] || 0
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

        recency_score = max(0, release_year - 1990) * 0.1
        rating_score = vote_average * :math.log10(max(vote_count, 1))
        final_score = rating_score * 0.7 + recency_score * 0.3

        final_score
      end,
      :desc
    )
  end

  # Enhanced sorting for other content sections
  defp sort_by_rating_and_popularity(titles) do
    current_year = Date.utc_today().year

    titles
    |> Enum.sort_by(
      fn title ->
        vote_average = title["vote_average"] || 0.0
        vote_count = title["vote_count"] || 0
        popularity = title["popularity"] || 0.0
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

        recency_score = max(0, release_year - 1990) * 0.1
        rating_score = vote_average * :math.log10(max(vote_count, 1))
        popularity_score = popularity * 0.05
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

  # Helper function to determine if content is inappropriate
  defp is_inappropriate_content?(title) do
    if title["adult"] == true do
      true
    else
      age_rating = title["certification"] || title["rating"] || title["age_rating"]

      case age_rating do
        rating when is_binary(rating) ->
          rating = String.upcase(rating)
          rating in ["18", "18+", "R", "NC-17", "X", "A", "18A", "R18", "R18+"]

        _ ->
          has_mature_content?(title)
      end
    end
  end

  # Check for mature content indicators
  defp has_mature_content?(title) do
    overview = String.downcase(title["overview"] || "")

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

    Enum.any?(mature_keywords, &String.contains?(overview, &1))
  end

  # Helper function to check if a title has no poster
  defp has_no_poster?(title) do
    poster_path = title["poster_path"]
    is_nil(poster_path) or poster_path == "" or poster_path == "null"
  end

  # Helper function to determine if load more button should be shown
  defp should_show_load_more?(section, section_data) do
    case section do
      "genre" ->
        # For genres, we fetch comprehensive coverage initially, so no need for load more
        false

      _ ->
        # For other sections, show load more if we have enough titles
        length(section_data) >= 30
    end
  end
end
