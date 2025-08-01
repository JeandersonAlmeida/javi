defmodule Javi.Accounts.UserProfile do
  @moduledoc """
  Helper module for managing user profiles and preferences in the movie/TV tracking application.
  """

  alias Javi.Accounts.User
  alias Javi.Repo
  import Ecto.Query

  @profile_visibilities ["public", "friends", "private"]
  @rating_scales [5, 10]
  @date_formats ["DD/MM/YYYY", "MM/DD/YYYY", "YYYY-MM-DD"]

  @doc """
  Returns all available profile visibility options.
  """
  def profile_visibilities, do: @profile_visibilities

  @doc """
  Returns all available rating scales.
  """
  def rating_scales, do: @rating_scales

  @doc """
  Returns all available date formats.
  """
  def date_formats, do: @date_formats

  @doc """
  Gets a user's display name or falls back to email.
  """
  def display_name(%User{display_name: display_name})
      when is_binary(display_name) and display_name != "" do
    display_name
  end

  def display_name(%User{email: email}), do: email

  @doc """
  Checks if a user's profile is public.
  """
  def public_profile?(%User{profile_visibility: "public"}), do: true
  def public_profile?(_), do: false

  @doc """
  Checks if a user's profile is visible to friends.
  """
  def friends_profile?(%User{profile_visibility: "friends"}), do: true
  def friends_profile?(_), do: false

  @doc """
  Checks if a user's profile is private.
  """
  def private_profile?(%User{profile_visibility: "private"}), do: true
  def private_profile?(_), do: false

  @doc """
  Checks if a user shows their ratings.
  """
  def shows_ratings?(%User{show_ratings: true}), do: true
  def shows_ratings?(_), do: false

  @doc """
  Checks if a user shows their watchlist.
  """
  def shows_watchlist?(%User{show_watchlist: true}), do: true
  def shows_watchlist?(_), do: false

  @doc """
  Checks if a user shows their favorites.
  """
  def shows_favorites?(%User{show_favorites: true}), do: true
  def shows_favorites?(_), do: false

  @doc """
  Checks if a user shows their watching list.
  """
  def shows_watching?(%User{show_watching: true}), do: true
  def shows_watching?(_), do: false

  @doc """
  Checks if a user shows their watched list.
  """
  def shows_watched?(%User{show_watched: true}), do: true
  def shows_watched?(_), do: false

  @doc """
  Checks if a user accepts friend requests.
  """
  def accepts_friend_requests?(%User{allow_friend_requests: true}), do: true
  def accepts_friend_requests?(_), do: false

  @doc """
  Checks if a user auto-accepts friends.
  """
  def auto_accepts_friends?(%User{auto_accept_friends: true}), do: true
  def auto_accepts_friends?(_), do: false

  @doc """
  Checks if a user has email notifications enabled.
  """
  def email_notifications_enabled?(%User{email_notifications: true}), do: true
  def email_notifications_enabled?(_), do: false

  @doc """
  Checks if a user has adult content filter enabled.
  """
  def adult_content_filter_enabled?(%User{adult_content_filter: true}), do: true
  def adult_content_filter_enabled?(_), do: false

  @doc """
  Gets user's preferred genres.
  """
  def preferred_genres(%User{preferred_genres: genres}) when is_list(genres), do: genres
  def preferred_genres(_), do: []

  @doc """
  Gets user's excluded genres.
  """
  def excluded_genres(%User{excluded_genres: genres}) when is_list(genres), do: genres
  def excluded_genres(_), do: []

  @doc """
  Checks if a user has a specific preferred genre.
  """
  def has_preferred_genre?(user, genre) do
    genre in preferred_genres(user)
  end

  @doc """
  Checks if a user has excluded a specific genre.
  """
  def has_excluded_genre?(user, genre) do
    genre in excluded_genres(user)
  end

  @doc """
  Gets user's minimum rating filter.
  """
  def min_rating_filter(%User{min_rating_filter: rating}) when is_integer(rating), do: rating
  def min_rating_filter(_), do: 0

  @doc """
  Gets user's rating scale.
  """
  def rating_scale(%User{rating_scale: scale}) when is_integer(scale), do: scale
  def rating_scale(_), do: 10

  @doc """
  Gets user's timezone.
  """
  def timezone(%User{timezone: tz}) when is_binary(tz), do: tz
  def timezone(_), do: "America/Sao_Paulo"

  @doc """
  Gets user's preferred language.
  """
  def preferred_language(%User{preferred_language: lang}) when is_binary(lang), do: lang
  def preferred_language(_), do: "pt-BR"

  @doc """
  Gets user's date format.
  """
  def date_format(%User{date_format: format}) when is_binary(format), do: format
  def date_format(_), do: "DD/MM/YYYY"

  @doc """
  Checks if a user's account is active.
  """
  def active_account?(%User{account_status: "active"}), do: true
  def active_account?(_), do: false

  @doc """
  Checks if a user's account is deleted.
  """
  def deleted_account?(%User{account_status: "deleted"}), do: true
  def deleted_account?(_), do: false

  @doc """
  Gets user's activity statistics.
  """
  def activity_stats(%User{} = user) do
    %{
      total_watched: user.total_watched || 0,
      total_watching: user.total_watching || 0,
      total_want_to_watch: user.total_want_to_watch || 0,
      total_favorites: user.total_favorites || 0,
      average_rating: user.average_rating,
      total_ratings_given: user.total_ratings_given || 0
    }
  end

  @doc """
  Updates user activity timestamp.
  """
  def update_activity(user) do
    user
    |> User.update_activity_changeset()
    |> Repo.update()
  end

  @doc """
  Updates user statistics based on their user_titles.
  """
  def update_statistics(user_id) do
    # Get statistics from user_titles
    stats =
      from(ut in Javi.Media.UserTitle,
        where: ut.user_id == ^user_id,
        select: %{
          total_watched: fragment("COUNT(CASE WHEN status = 'watched' THEN 1 END)"),
          total_watching: fragment("COUNT(CASE WHEN status = 'watching' THEN 1 END)"),
          total_want_to_watch: fragment("COUNT(CASE WHEN status = 'want_to_watch' THEN 1 END)"),
          total_favorites: fragment("COUNT(CASE WHEN status = 'favorite' THEN 1 END)"),
          average_rating: fragment("AVG(CASE WHEN rating IS NOT NULL THEN rating END)"),
          total_ratings_given: fragment("COUNT(CASE WHEN rating IS NOT NULL THEN 1 END)")
        }
      )
      |> Repo.one()

    # Update user with new statistics
    user = Repo.get(User, user_id)

    if user do
      user
      |> User.activity_changeset(%{
        total_watched: stats.total_watched || 0,
        total_watching: stats.total_watching || 0,
        total_want_to_watch: stats.total_want_to_watch || 0,
        total_favorites: stats.total_favorites || 0,
        average_rating: stats.average_rating,
        total_ratings_given: stats.total_ratings_given || 0
      })
      |> Repo.update()
    end
  end

  @doc """
  Gets users with public profiles.
  """
  def get_public_users(limit \\ 20) do
    from(u in User,
      where: u.profile_visibility == "public" and u.account_status == "active",
      order_by: [desc: u.last_activity_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Searches users by display name or bio.
  """
  def search_users(query, limit \\ 20) do
    search_term = "%#{query}%"

    from(u in User,
      where:
        (ilike(u.display_name, ^search_term) or ilike(u.bio, ^search_term)) and
          u.account_status == "active",
      order_by: [desc: u.last_activity_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets users by preferred genre.
  """
  def get_users_by_preferred_genre(genre, limit \\ 20) do
    from(u in User,
      where: ^genre in u.preferred_genres and u.account_status == "active",
      order_by: [desc: u.last_activity_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets users with similar preferences.
  """
  def get_users_with_similar_preferences(user, limit \\ 10) do
    preferred_genres = preferred_genres(user)

    if Enum.empty?(preferred_genres) do
      []
    else
      from(u in User,
        where:
          u.id != ^user.id and u.account_status == "active" and
            fragment("? && ?", u.preferred_genres, ^preferred_genres),
        order_by: [desc: u.last_activity_at],
        limit: ^limit
      )
      |> Repo.all()
    end
  end

  @doc """
  Gets users by activity level.
  """
  def get_active_users(hours_ago \\ 24, limit \\ 20) do
    cutoff_time = DateTime.add(DateTime.utc_now(), -hours_ago * 3600, :second)

    from(u in User,
      where: u.last_activity_at > ^cutoff_time and u.account_status == "active",
      order_by: [desc: u.last_activity_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets users with high ratings.
  """
  def get_users_with_high_ratings(min_rating \\ 7.0, limit \\ 20) do
    from(u in User,
      where: u.average_rating >= ^min_rating and u.account_status == "active",
      order_by: [desc: u.average_rating],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets users by timezone.
  """
  def get_users_by_timezone(timezone, limit \\ 20) do
    from(u in User,
      where: u.timezone == ^timezone and u.account_status == "active",
      order_by: [desc: u.last_activity_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets users by language preference.
  """
  def get_users_by_language(language, limit \\ 20) do
    from(u in User,
      where: u.preferred_language == ^language and u.account_status == "active",
      order_by: [desc: u.last_activity_at],
      limit: ^limit
    )
    |> Repo.all()
  end
end
