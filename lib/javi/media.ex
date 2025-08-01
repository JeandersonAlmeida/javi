defmodule Javi.Media do
  @moduledoc """
  The Media context provides functions for managing titles and user interactions.
  """

  import Ecto.Query, warn: false
  alias Javi.Repo
  alias Javi.Media.{Title, UserTitle}
  alias Javi.Accounts.{User, List, ListItem}
  alias Javi.Media.TMDB.Client, as: TMDBClient

  # Title functions

  @doc """
  Gets a single title by TMDB ID and type.
  """
  def get_title_by_tmdb_id(tmdb_id, tmdb_type) do
    Title.get_by_tmdb_id(tmdb_id, tmdb_type)
    |> Repo.one()
  end

  @doc """
  Creates a new title.
  """
  def create_title(attrs \\ %{}) do
    %Title{}
    |> Title.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a title.
  """
  def update_title(%Title{} = title, attrs) do
    title
    |> Title.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets or creates a title by TMDB ID and type.
  """
  def get_or_create_title(tmdb_id, tmdb_type, attrs) do
    case get_title_by_tmdb_id(tmdb_id, tmdb_type) do
      nil ->
        # Try to fetch full details from TMDB to get duration data
        full_attrs = fetch_full_details_from_tmdb(tmdb_id, tmdb_type, attrs)
        create_title(Map.merge(full_attrs, %{tmdb_id: tmdb_id, tmdb_type: tmdb_type}))

      title ->
        {:ok, title}
    end
  end

  defp fetch_full_details_from_tmdb(tmdb_id, tmdb_type, attrs) do
    # Only fetch TMDB data if we don't have duration information
    has_duration_data =
      case tmdb_type do
        "movie" -> not is_nil(attrs[:runtime])
        "tv" -> not is_nil(attrs[:episode_run_time]) or not is_nil(attrs[:number_of_episodes])
        _ -> false
      end

    if has_duration_data do
      # If we already have duration data, just return the attrs
      attrs
    else
      # Fetch full details from TMDB to get duration data
      case tmdb_type do
        "movie" ->
          case TMDBClient.get_movie_details(tmdb_id) do
            {:ok, movie_data} ->
              # Only merge duration fields, keep existing attrs for other fields
              attrs
              |> Map.merge(%{
                runtime: movie_data["runtime"],
                episode_run_time: movie_data["episode_run_time"],
                number_of_seasons: movie_data["number_of_seasons"],
                number_of_episodes: movie_data["number_of_episodes"]
              })

            {:error, _} ->
              attrs
          end

        "tv" ->
          case TMDBClient.get_tv_details(tmdb_id) do
            {:ok, tv_data} ->
              # Only merge duration fields, keep existing attrs for other fields
              attrs
              |> Map.merge(%{
                runtime: tv_data["runtime"],
                episode_run_time: tv_data["episode_run_time"],
                number_of_seasons: tv_data["number_of_seasons"],
                number_of_episodes: tv_data["number_of_episodes"]
              })

            {:error, _} ->
              attrs
          end

        _ ->
          attrs
      end
    end
  end

  @doc """
  Updates a title if it exists, creates it if it doesn't.
  """
  def upsert_title(tmdb_id, tmdb_type, attrs) do
    case get_title_by_tmdb_id(tmdb_id, tmdb_type) do
      nil ->
        create_title(Map.merge(attrs, %{tmdb_id: tmdb_id, tmdb_type: tmdb_type}))

      title ->
        update_title(title, attrs)
    end
  end

  @doc """
  Searches titles by query.
  """
  def search_titles(query) do
    Title.search_titles(query)
    |> Repo.all()
  end

  @doc """
  Gets titles by type.
  """
  def get_titles_by_type(tmdb_type) do
    Title.get_by_type(tmdb_type)
    |> Repo.all()
  end

  @doc """
  Gets titles by genre.
  """
  def get_titles_by_genre(genre) do
    Title.get_by_genre(genre)
    |> Repo.all()
  end

  @doc """
  Gets popular titles.
  """
  def get_popular_titles(limit \\ 20) do
    Title.get_popular_titles(limit)
    |> Repo.all()
  end

  @doc """
  Gets highly rated titles.
  """
  def get_highly_rated_titles(limit \\ 20) do
    Title.get_highly_rated_titles(limit)
    |> Repo.all()
  end

  @doc """
  Gets stale titles that need updating.
  """
  def get_stale_titles(hours_ago \\ 24) do
    Title.get_stale_titles(hours_ago)
    |> Repo.all()
  end

  @doc """
  Gets a title by ID.

  ## Examples

      iex> get_title(123)
      %Title{}

      iex> get_title(456)
      nil

  """
  def get_title(id) do
    Repo.get(Title, id)
  end

  @doc """
  UserTitle functions
  """
  def get_user_title(user_id, title_id) do
    UserTitle.get_by_user_and_title(user_id, title_id)
    |> Repo.one()
  end

  @doc """
  Creates a new user title interaction.
  """
  def create_user_title(attrs \\ %{}) do
    %UserTitle{}
    |> UserTitle.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user title interaction.
  """
  def update_user_title(%UserTitle{} = user_title, attrs) do
    user_title
    |> UserTitle.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates or updates a user title interaction.
  """
  def upsert_user_title(user_id, title_id, attrs) do
    case get_user_title(user_id, title_id) do
      nil ->
        create_user_title(Map.merge(attrs, %{user_id: user_id, title_id: title_id}))

      user_title ->
        update_user_title(user_title, attrs)
    end
  end

  @doc """
  Marks a title as watched by a user.
  """
  def mark_as_watched(user_id, title_id, attrs \\ %{}) do
    case get_user_title(user_id, title_id) do
      nil ->
        %UserTitle{}
        |> UserTitle.changeset(
          Map.merge(attrs, %{user_id: user_id, title_id: title_id, status: :watched})
        )
        |> Repo.insert()

      user_title ->
        user_title
        |> UserTitle.watched_changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Marks a title as watching by a user.
  """
  def mark_as_watching(user_id, title_id, attrs \\ %{}) do
    case get_user_title(user_id, title_id) do
      nil ->
        %UserTitle{}
        |> UserTitle.changeset(
          Map.merge(attrs, %{user_id: user_id, title_id: title_id, status: :watching})
        )
        |> Repo.insert()

      user_title ->
        user_title
        |> UserTitle.watching_changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Marks a title as want to watch by a user.
  """
  def mark_as_want_to_watch(user_id, title_id, attrs \\ %{}) do
    case get_user_title(user_id, title_id) do
      nil ->
        %UserTitle{}
        |> UserTitle.changeset(
          Map.merge(attrs, %{user_id: user_id, title_id: title_id, status: :want_to_watch})
        )
        |> Repo.insert()

      user_title ->
        user_title
        |> UserTitle.want_to_watch_changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Marks a title as favorite by a user.
  """
  def mark_as_favorite(user_id, title_id, attrs \\ %{}) do
    case get_user_title(user_id, title_id) do
      nil ->
        %UserTitle{}
        |> UserTitle.changeset(
          Map.merge(attrs, %{user_id: user_id, title_id: title_id, status: :favorite})
        )
        |> Repo.insert()

      user_title ->
        user_title
        |> UserTitle.favorite_changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Gets all user titles for a specific user.
  """
  def get_user_titles(user_id) do
    UserTitle.get_by_user(user_id)
    |> Repo.all()
  end

  @doc """
  Gets user titles by status.
  """
  def get_user_titles_by_status(user_id, status) do
    UserTitle.get_by_status(user_id, status)
    |> Repo.all()
  end

  @doc """
  Gets user's watched titles.
  """
  def get_watched_titles(user_id) do
    get_user_titles_by_status(user_id, :watched)
  end

  @doc """
  Gets user's watching titles.
  """
  def get_watching_titles(user_id) do
    get_user_titles_by_status(user_id, :watching)
  end

  @doc """
  Gets user's want to watch titles.
  """
  def get_want_to_watch_titles(user_id) do
    get_user_titles_by_status(user_id, :want_to_watch)
  end

  @doc """
  Gets user's favorite titles.
  """
  def get_favorite_titles(user_id) do
    get_user_titles_by_status(user_id, :favorite)
  end

  @doc """
  Gets user titles with ratings.
  """
  def get_user_titles_with_ratings(user_id) do
    UserTitle.get_with_ratings(user_id)
    |> Repo.all()
  end

  @doc """
  Gets recently watched titles.
  """
  def get_recently_watched_titles(user_id, limit \\ 10) do
    UserTitle.get_recently_watched(user_id, limit)
    |> Repo.all()
  end

  @doc """
  Gets recent watched titles with title details.
  """
  def get_recent_watched_titles(user_id, limit \\ 5) do
    from(ut in UserTitle,
      join: t in Title,
      on: t.id == ut.title_id,
      where: ut.user_id == ^user_id and ut.status == :watched,
      order_by: [desc: ut.updated_at],
      limit: ^limit,
      select: %{
        id: ut.id,
        status: ut.status,
        rating: ut.rating,
        date_watched: ut.date_watched,
        title: t.title,
        tmdb_type: t.tmdb_type,
        poster_path: t.poster_path,
        overview: t.overview,
        release_date: t.release_date,
        vote_average: t.vote_average
      }
    )
    |> Repo.all()
  end

  @doc """
  Gets user statistics.
  """
  def get_user_stats(user_id) do
    UserTitle.get_user_stats(user_id)
    |> Repo.one()
  end

  @doc """
  Gets a watched list item by user and title ID.
  """
  def get_watched_list_item_by_title_id(user, title_id) do
    watched_list = get_user_watched_list(user)

    case watched_list do
      nil ->
        nil

      list ->
        from(li in Javi.Accounts.ListItem,
          where: li.list_id == ^list.id and li.title_id == ^title_id,
          limit: 1
        )
        |> Repo.one()
    end
  end

  @doc """
  Updates the rating of a watched list item.
  """
  def update_watched_list_item_rating(user, title_id, rating) do
    case get_watched_list_item_by_title_id(user, title_id) do
      nil ->
        {:error, :not_found}

      list_item ->
        list_item
        |> Javi.Accounts.ListItem.update_changeset(%{rating: rating})
        |> Repo.update()
    end
  end

  @doc """
  Deletes a user title interaction.
  """
  def delete_user_title(%UserTitle{} = user_title) do
    Repo.delete(user_title)
  end

  @doc """
  Deletes a user title interaction by user and title IDs.
  """
  def delete_user_title(user_id, title_id) do
    case get_user_title(user_id, title_id) do
      nil ->
        {:error, :not_found}

      user_title ->
        delete_user_title(user_title)
    end
  end

  # Combined queries

  @doc """
  Gets titles with user interactions for a specific user.
  """
  def get_titles_with_user_interactions(user_id, limit \\ 20) do
    from(t in Title,
      left_join: ut in UserTitle,
      on: ut.title_id == t.id and ut.user_id == ^user_id,
      order_by: [desc: t.popularity, desc: t.vote_average],
      limit: ^limit,
      preload: [user_titles: ut]
    )
    |> Repo.all()
  end

  @doc """
  Gets titles that a user hasn't interacted with.
  """
  def get_unwatched_titles(user_id, limit \\ 20) do
    from(t in Title,
      left_join: ut in UserTitle,
      on: ut.title_id == t.id and ut.user_id == ^user_id,
      where: is_nil(ut.id),
      order_by: [desc: t.popularity, desc: t.vote_average],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets recommendations for a user based on their watched titles.
  """
  def get_recommendations_for_user(user_id, limit \\ 10) do
    # Get genres from user's watched titles
    watched_genres =
      from(ut in UserTitle,
        join: t in Title,
        on: t.id == ut.title_id,
        where: ut.user_id == ^user_id and ut.status == :watched,
        select: fragment("unnest(?)", t.genres)
      )
      |> Repo.all()
      |> Enum.flat_map(& &1)
      |> Enum.frequencies()
      |> Enum.sort_by(fn {_genre, count} -> count end, :desc)
      |> Enum.take(3)
      |> Enum.map(fn {genre, _count} -> genre end)

    # Get titles with similar genres that user hasn't watched
    from(t in Title,
      left_join: ut in UserTitle,
      on: ut.title_id == t.id and ut.user_id == ^user_id,
      where: is_nil(ut.id) and fragment("? && ?", t.genres, ^watched_genres),
      order_by: [desc: t.popularity, desc: t.vote_average],
      limit: ^limit
    )
    |> Repo.all()
  end

  ## List Management

  @doc """
  Adds a title to a user's watched list.
  """
  def add_title_to_watched_list(%User{} = user, title_data) do
    # First, get or create the title
    case get_or_create_title(title_data["id"], title_data["media_type"] || "movie", %{
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
        # Get the user's watched list
        watched_list =
          List
          |> where([l], l.user_id == ^user.id and l.list_type == "watched")
          |> Repo.one()

        case watched_list do
          nil ->
            {:error, :watched_list_not_found}

          list ->
            # Add title to the watched list
            case Javi.Accounts.add_title_to_list(list, title) do
              {:ok, list_item} ->
                # Broadcast event to refresh dashboard stats
                Phoenix.PubSub.broadcast(
                  Javi.PubSub,
                  "user_stats:#{user.id}",
                  {:stats_updated, user.id}
                )

                {:ok, list_item}

              {:error, changeset} ->
                {:error, changeset}
            end
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Checks if a title is in a user's watched list.
  """
  def is_title_in_watched_list(%User{} = user, title_id) do
    case get_user_title(user.id, title_id) do
      nil -> false
      user_title -> user_title.status == :watched
    end
  end

  @doc """
  Gets a user's watched list.
  """
  def get_user_watched_list(%User{} = user) do
    List
    |> where([l], l.user_id == ^user.id and l.list_type == "watched")
    |> preload(list_items: :title)
    |> Repo.one()
  end

  # Private helper functions

  defp convert_genre_ids_to_strings(genre_ids) when is_list(genre_ids) do
    genre_ids
    |> Enum.map(&to_string/1)
    |> Enum.filter(&(&1 != nil))
  end

  defp convert_genre_ids_to_strings(_), do: []

  @doc """
  Calculates the total time spent watching content based on actual title durations.
  """
  def calculate_actual_time_spent(user_id) do
    import Ecto.Query

    # Get watched titles from UserTitle
    user_title_minutes =
      from(ut in UserTitle,
        join: t in Title,
        on: ut.title_id == t.id,
        where: ut.user_id == ^user_id and ut.status == :watched,
        select: %{
          tmdb_type: t.tmdb_type,
          runtime: t.runtime,
          episode_run_time: t.episode_run_time,
          number_of_episodes: t.number_of_episodes
        }
      )
      |> Repo.all()
      |> Enum.map(fn title -> calculate_title_minutes(title) end)
      |> Enum.sum()

    # Get watched titles from watched list
    list_minutes =
      from(li in ListItem,
        join: l in List,
        on: li.list_id == l.id,
        join: t in Title,
        on: li.title_id == t.id,
        where: l.user_id == ^user_id and l.list_type == "watched",
        select: %{
          tmdb_type: t.tmdb_type,
          runtime: t.runtime,
          episode_run_time: t.episode_run_time,
          number_of_episodes: t.number_of_episodes
        }
      )
      |> Repo.all()
      |> Enum.map(fn title -> calculate_title_minutes(title) end)
      |> Enum.sum()

    user_title_minutes + list_minutes
  end

  defp calculate_title_minutes(%{tmdb_type: "movie", runtime: runtime})
       when not is_nil(runtime) do
    runtime
  end

  defp calculate_title_minutes(%{
         tmdb_type: "tv",
         episode_run_time: episode_run_time,
         number_of_episodes: number_of_episodes
       })
       when not is_nil(episode_run_time) and not is_nil(number_of_episodes) do
    # Use the first episode runtime if it's an array
    episode_runtime =
      if is_list(episode_run_time), do: Enum.at(episode_run_time, 0), else: episode_run_time

    episode_runtime * number_of_episodes
  end

  defp calculate_title_minutes(%{tmdb_type: "tv", episode_run_time: episode_run_time})
       when not is_nil(episode_run_time) do
    # If we have episode runtime but no episode count, assume 1 episode
    episode_runtime =
      if is_list(episode_run_time), do: Enum.at(episode_run_time, 0), else: episode_run_time

    episode_runtime
  end

  defp calculate_title_minutes(_), do: 0
end
