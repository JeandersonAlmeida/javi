defmodule JaviWeb.Home.DashboardLive do
  use JaviWeb, :live_view

  alias Javi.Media.TMDB.Client, as: TMDBClient
  alias Javi.Media
  alias Javi.Accounts
  import JaviWeb.Components.BottomNavigation

  @impl true
  def mount(_params, session, socket) do
    # Get current user
    user = get_current_user(session)

    # Check if user has completed onboarding
    if user && !user.onboarding_completed do
      {:ok, push_navigate(socket, to: ~p"/onboarding")}
    else
      # Get user statistics
      user_stats = get_user_statistics(user)

      # Get user lists
      user_lists = get_user_lists(user)
      default_lists = get_default_lists(user_lists)
      custom_lists = get_custom_lists(user_lists)
      all_lists = default_lists ++ custom_lists

      # Get recent movies from TMDB
      recent_movies =
        case TMDBClient.get_recent_movies() do
          {:ok, %{"results" => results}} -> results
          {:error, _reason} -> []
        end

      # Get top searches from TMDB
      top_searches =
        case TMDBClient.get_top_searches() do
          {:ok, %{"results" => results}} -> results
          {:error, _reason} -> []
        end

      # Subscribe to user stats updates if user is logged in
      if user do
        Phoenix.PubSub.subscribe(Javi.PubSub, "user_stats:#{user.id}")
      end

      {:ok,
       assign(socket,
         user: user,
         user_stats: user_stats,
         user_lists: user_lists,
         all_lists: all_lists,
         recent_movies: recent_movies,
         query: "",
         search_results: [],
         top_searches: top_searches,
         current_page: :home,
         show_modal: false,
         selected_title: nil,
         selected_lists: []
       )}
    end
  end

  @impl true
  def handle_event("search", %{"value" => value}, socket) do
    query = String.trim(value)

    case TMDBClient.search_movies(query) do
      {:ok, %{"results" => results}} ->
        {:noreply, assign(socket, search_results: results, query: query)}

      {:error, _reason} ->
        {:noreply, assign(socket, search_results: [], query: query)}
    end
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, assign(socket, search_results: [], query: "")}
  end

  @impl true
  def handle_event("navigate_to_list", %{"list-id" => list_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/listas/#{list_id}")}
  end

  @impl true
  def handle_event("navigate_to_lists", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/listas")}
  end

  @impl true
  def handle_event("navigate_to_search", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/pesquisar")}
  end

  @impl true
  def handle_event("navigate_to_profile", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/perfil")}
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
            {:noreply, push_navigate(socket, to: ~p"/titulos/#{title.id}?referrer=dashboard")}

          {:error, _changeset} ->
            {:noreply, socket}
        end

      {:error, _error} ->
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
  def handle_event("go_back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/inicio")}
  end

  @impl true
  def handle_info({:stats_updated, user_id}, socket) do
    case socket.assigns.user do
      %{id: ^user_id} ->
        # Refresh user statistics
        user_stats = get_user_statistics(socket.assigns.user)
        {:noreply, assign(socket, user_stats: user_stats)}

      _ ->
        {:noreply, socket}
    end
  end

  # Private functions

  defp get_current_user(session) do
    case session["user_token"] do
      nil -> nil
      token -> Accounts.get_user_by_session_token(token)
    end
  end

  defp get_user_statistics(user) do
    case user do
      nil ->
        %{
          total_watched: 0,
          total_watching: 0,
          total_want_to_watch: 0,
          total_favorites: 0,
          watched_movies: 0,
          watched_tv_series: 0,
          time_spent: "0h"
        }

      user ->
        watched_movies = count_watched_movies(user)
        watched_tv_series = count_watched_tv_series(user)
        _total_watched = watched_movies + watched_tv_series
        actual_minutes = Media.calculate_actual_time_spent(user.id)

        %{
          total_watched: user.total_watched || 0,
          total_watching: user.total_watching || 0,
          total_want_to_watch: user.total_want_to_watch || 0,
          total_favorites: user.total_favorites || 0,
          watched_movies: watched_movies,
          watched_tv_series: watched_tv_series,
          time_spent: format_time_from_minutes(actual_minutes)
        }
    end
  end

  defp get_user_lists(user) do
    case user do
      nil -> []
      user -> Accounts.get_user_lists(user)
    end
  end

  defp get_default_lists(user_lists) do
    user_lists
    |> Enum.filter(fn list ->
      list.list_type in ["watched", "watching", "favorites", "want_to_watch"]
    end)
    |> Enum.sort_by(fn list ->
      case list.list_type do
        "watched" -> 1
        "watching" -> 2
        "want_to_watch" -> 3
        "favorites" -> 4
        _ -> 5
      end
    end)
  end

  defp get_custom_lists(user_lists) do
    user_lists
    |> Enum.filter(fn list -> list.list_type == "custom" end)
    |> Enum.sort_by(& &1.inserted_at, :desc)
  end

  defp get_list_background_style(list) do
    # Get the first item's poster as background, or use a default gradient
    case list.list_items do
      [first_item | _]
      when not is_nil(first_item.title) and not is_nil(first_item.title.poster_path) ->
        "background-image: url(\"https://image.tmdb.org/t/p/w500#{first_item.title.poster_path}\");"

      _ ->
        # Default gradient backgrounds based on list type
        case list.list_type do
          "watching" ->
            "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);"

          "want_to_watch" ->
            "background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);"

          "favorites" ->
            "background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);"

          "watched" ->
            "background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);"

          _ ->
            "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);"
        end
    end
  end

  defp count_watched_movies(user) do
    import Ecto.Query

    # Count from UserTitle with watched status
    user_title_count =
      from(ut in Javi.Media.UserTitle,
        join: t in Javi.Media.Title,
        on: ut.title_id == t.id,
        where: ut.user_id == ^user.id and ut.status == :watched and t.tmdb_type == "movie"
      )
      |> Javi.Repo.aggregate(:count, :id)

    # Count from watched list
    list_count =
      from(li in Javi.Accounts.ListItem,
        join: l in Javi.Accounts.List,
        on: li.list_id == l.id,
        join: t in Javi.Media.Title,
        on: li.title_id == t.id,
        where: l.user_id == ^user.id and l.list_type == "watched" and t.tmdb_type == "movie"
      )
      |> Javi.Repo.aggregate(:count, :id)

    user_title_count + list_count
  end

  defp count_watched_tv_series(user) do
    import Ecto.Query

    # Count from UserTitle with watched status
    user_title_count =
      from(ut in Javi.Media.UserTitle,
        join: t in Javi.Media.Title,
        on: ut.title_id == t.id,
        where: ut.user_id == ^user.id and ut.status == :watched and t.tmdb_type == "tv"
      )
      |> Javi.Repo.aggregate(:count, :id)

    # Count from watched list
    list_count =
      from(li in Javi.Accounts.ListItem,
        join: l in Javi.Accounts.List,
        on: li.list_id == l.id,
        join: t in Javi.Media.Title,
        on: li.title_id == t.id,
        where: l.user_id == ^user.id and l.list_type == "watched" and t.tmdb_type == "tv"
      )
      |> Javi.Repo.aggregate(:count, :id)

    user_title_count + list_count
  end

  defp format_time_from_minutes(minutes) do
    cond do
      minutes == 0 -> "0h"
      minutes < 60 -> "#{minutes}m"
      minutes < 1440 -> "#{div(minutes, 60)}h #{rem(minutes, 60)}m"
      minutes < 10080 -> "#{div(minutes, 1440)}d #{div(rem(minutes, 1440), 60)}h"
      true -> "#{div(minutes, 10080)}w #{div(rem(minutes, 10080), 1440)}d"
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
