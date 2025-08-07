defmodule JaviWeb.Home.ProfileLive do
  use JaviWeb, :live_view

  alias Javi.Accounts
  alias Javi.Repo
  import JaviWeb.Components.BottomNavigation
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    # Get current user
    user = get_current_user(session)

    # Get user statistics using the same functions as user settings
    user_stats = get_user_statistics(user)

    # Get last 5 watched titles using the same function as user settings
    recent_watched = get_recent_watched_titles(user)

    {:ok,
     assign(socket,
       user: user,
       user_stats: user_stats,
       recent_watched: recent_watched,
       current_page: :profile,
       dropdown_open: false
     )}
  end

  @impl true
  def handle_event("navigate_to_search", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/pesquisar")}
  end

  @impl true
  def handle_event("logout", _params, socket) do
    {:noreply, push_event(socket, "logout", %{})}
  end

  @impl true
  def handle_event("toggle_dropdown", _params, socket) do
    {:noreply, assign(socket, dropdown_open: !socket.assigns.dropdown_open)}
  end

  @impl true
  def handle_event("close_dropdown", _params, socket) do
    {:noreply, assign(socket, dropdown_open: false)}
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
          time_spent: "0h",
          top_genre: "N/A",
          average_rating: Decimal.new("0.0"),
          total_ratings: 0
        }

      user ->
        # Get statistics from Lists system (same as user settings)
        watched_count = get_list_item_count(user.id, "watched")
        watching_count = get_list_item_count(user.id, "watching")
        want_to_watch_count = get_list_item_count(user.id, "want_to_watch")
        favorites_count = get_list_item_count(user.id, "favorites")
        average_rating = get_average_rating(user.id)

        %{
          total_watched: watched_count,
          total_watching: watching_count,
          total_want_to_watch: want_to_watch_count,
          total_favorites: favorites_count,
          time_spent: calculate_time_spent(watched_count),
          top_genre: get_top_genre(user),
          average_rating: average_rating,
          # Using watched count as proxy for ratings given
          total_ratings: watched_count
        }
    end
  end

  defp get_list_item_count(user_id, list_type) do
    alias Javi.Accounts.{List, ListItem}

    result =
      List
      |> join(:inner, [l], li in ListItem, on: l.id == li.list_id)
      |> where([l, li], l.user_id == ^user_id and l.list_type == ^list_type)
      |> select([l, li], count(li.id))
      |> Repo.one()

    result || 0
  end

  defp get_average_rating(user_id) do
    alias Javi.Accounts.{List, ListItem}

    result =
      List
      |> join(:inner, [l], li in ListItem, on: l.id == li.list_id)
      |> where(
        [l, li],
        l.user_id == ^user_id and l.list_type == "watched" and not is_nil(li.rating)
      )
      |> select([l, li], avg(li.rating))
      |> Repo.one()

    case result do
      nil -> Decimal.new("0.0")
      avg_rating -> avg_rating
    end
  end

  defp get_recent_list_items(user_id, list_type, limit) do
    alias Javi.Accounts.{List, ListItem}
    alias Javi.Media.Title

    List
    |> join(:inner, [l], li in ListItem, on: l.id == li.list_id)
    |> join(:inner, [l, li], t in Title, on: li.title_id == t.id)
    |> where([l, li, t], l.user_id == ^user_id and l.list_type == ^list_type)
    |> order_by([l, li, t], desc: li.inserted_at)
    |> limit(^limit)
    |> select([l, li, t], %{
      id: li.id,
      status: l.list_type,
      rating: li.rating,
      date_watched: li.inserted_at,
      title: t.title,
      tmdb_type: t.tmdb_type,
      poster_path: t.poster_path,
      overview: t.overview,
      release_date: t.release_date,
      vote_average: t.vote_average
    })
    |> Repo.all()
  end

  defp get_recent_watched_titles(user) do
    case user do
      nil -> []
      user -> get_recent_list_items(user.id, "watched", 5)
    end
  end

  defp calculate_time_spent(total_watched) do
    # Assuming average 2 hours per movie/show
    total_hours = total_watched * 2
    "#{total_hours}h"
  end

  defp get_top_genre(user) do
    case user.preferred_genres do
      nil -> "N/A"
      [] -> "N/A"
      genres -> List.first(genres)
    end
  end
end
