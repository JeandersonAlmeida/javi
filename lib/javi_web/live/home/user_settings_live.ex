defmodule JaviWeb.Home.UserSettingsLive do
  use JaviWeb, :live_view

  alias Javi.Accounts
  alias Javi.Repo
  import JaviWeb.Components.Header
  import Ecto.Query

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email alterado com sucesso.")

        :error ->
          put_flash(socket, :error, "O link para alterar o email é inválido ou expirou.")
      end

    {:ok, push_navigate(socket, to: ~p"/configuracoes")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    profile_changeset = Accounts.change_user_profile(user)

    # Get privacy and social settings
    privacy_settings = get_privacy_settings(user)
    social_settings = get_social_settings(user)

    # Get user statistics
    user_stats = get_user_statistics(user)

    # Get last 5 watched titles
    recent_watched = get_recent_watched_titles(user)

    socket =
      socket
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:current_password, nil)
      |> assign(:trigger_submit, false)
      |> assign(:privacy_settings, privacy_settings)
      |> assign(:social_settings, social_settings)
      |> assign(:user_stats, user_stats)
      |> assign(:recent_watched, recent_watched)
      |> assign(:current_page, :profile)
      # Nickname availability state for live feedback
      |> assign(:nickname_available, true)

    {:ok, socket}
  end

  def handle_event("validate_email", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :email_form, to_form(changeset))}
  end

  def handle_event("update_email", %{"user" => user_params}, socket) do
    case Accounts.apply_user_email(socket.assigns.current_user, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          applied_user.email,
          &url(~p"/configuracoes/confirmar-email/#{&1}")
        )

        info =
          "A confirmation link has been sent to your new email address. Please check your email to confirm the change."

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> assign(:trigger_submit, true)
         |> assign(:email_form, to_form(Accounts.change_user_email(applied_user)))}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  # Profile form handlers
  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)

    nickname = Map.get(user_params, "nickname") || ""

    available =
      if String.trim(nickname) == "" do
        true
      else
        Accounts.nickname_available?(nickname, socket.assigns.current_user.id)
      end

    {:noreply,
     socket
     |> assign(:profile_form, to_form(changeset))
     |> assign(:nickname_available, available)}
  end

  def handle_event("update_profile", %{"user" => user_params}, socket) do
    case Accounts.update_user_profile(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        socket =
          socket
          |> put_flash(:info, "Perfil atualizado com sucesso.")
          |> assign(:profile_form, to_form(Accounts.change_user_profile(user)))
          |> assign(:current_user, user)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  # Password form handlers
  def handle_event("validate_password", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :password_form, to_form(changeset))}
  end

  def handle_event("update_password", %{"user" => user_params}, socket) do
    case Accounts.update_user_password(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        socket =
          socket
          |> put_flash(:info, "Senha alterada com sucesso.")
          |> assign(:password_form, to_form(Accounts.change_user_password(user)))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :password_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  # Account management handlers
  def handle_event("delete_account", _params, socket) do
    # TODO: Implement account deletion with confirmation
    {:noreply,
     put_flash(socket, :info, "Funcionalidade de exclusão de conta será implementada em breve.")}
  end

  def handle_event("export_data", _params, socket) do
    # TODO: Implement data export functionality
    {:noreply, put_flash(socket, :info, "Funcionalidade de exportação em desenvolvimento.")}
  end

  # Privacy settings handlers
  def handle_event("toggle_public_profile", _params, socket) do
    current_value = socket.assigns.privacy_settings.public_profile
    new_settings = Map.put(socket.assigns.privacy_settings, :public_profile, !current_value)

    case Accounts.update_user_privacy_settings(socket.assigns.current_user, new_settings) do
      {:ok, _user} ->
        {:noreply, assign(socket, :privacy_settings, new_settings)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("toggle_show_activity", _params, socket) do
    current_value = socket.assigns.privacy_settings.show_activity
    new_settings = Map.put(socket.assigns.privacy_settings, :show_activity, !current_value)

    case Accounts.update_user_privacy_settings(socket.assigns.current_user, new_settings) do
      {:ok, _user} ->
        {:noreply, assign(socket, :privacy_settings, new_settings)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("toggle_allow_messages", _params, socket) do
    current_value = socket.assigns.privacy_settings.allow_messages
    new_settings = Map.put(socket.assigns.privacy_settings, :allow_messages, !current_value)

    case Accounts.update_user_privacy_settings(socket.assigns.current_user, new_settings) do
      {:ok, _user} ->
        {:noreply, assign(socket, :privacy_settings, new_settings)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  # Social settings handlers
  def handle_event("toggle_follower_notifications", _params, socket) do
    current_value = socket.assigns.social_settings.follower_notifications

    new_settings =
      Map.put(socket.assigns.social_settings, :follower_notifications, !current_value)

    case Accounts.update_user_social_settings(socket.assigns.current_user, new_settings) do
      {:ok, _user} ->
        {:noreply, assign(socket, :social_settings, new_settings)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("toggle_share_lists", _params, socket) do
    current_value = socket.assigns.social_settings.share_lists
    new_settings = Map.put(socket.assigns.social_settings, :share_lists, !current_value)

    case Accounts.update_user_social_settings(socket.assigns.current_user, new_settings) do
      {:ok, _user} ->
        {:noreply, assign(socket, :social_settings, new_settings)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("toggle_social_recommendations", _params, socket) do
    current_value = socket.assigns.social_settings.social_recommendations

    new_settings =
      Map.put(socket.assigns.social_settings, :social_recommendations, !current_value)

    case Accounts.update_user_social_settings(socket.assigns.current_user, new_settings) do
      {:ok, _user} ->
        {:noreply, assign(socket, :social_settings, new_settings)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  # Photo handlers
  def handle_event("change_photo", _params, socket) do
    # TODO: Implement photo upload functionality
    {:noreply,
     put_flash(socket, :info, "Funcionalidade de upload de foto será implementada em breve.")}
  end

  def handle_event("remove_photo", _params, socket) do
    case Accounts.remove_user_photo(socket.assigns.current_user) do
      {:ok, user} ->
        socket =
          socket
          |> put_flash(:info, "Foto removida com sucesso.")
          |> assign(:current_user, user)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao remover foto.")}
    end
  end

  @impl true
  def handle_event("navigate_to_search", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/pesquisar")}
  end

  @impl true
  def handle_event("toggle_email_notifications", _params, socket) do
    new_value = !socket.assigns.social_settings.email_notifications
    updated_settings = Map.put(socket.assigns.social_settings, :email_notifications, new_value)
    {:noreply, assign(socket, :social_settings, updated_settings)}
  end

  @impl true
  def handle_event("toggle_new_releases_notifications", _params, socket) do
    new_value = !socket.assigns.social_settings.new_releases_notifications

    updated_settings =
      Map.put(socket.assigns.social_settings, :new_releases_notifications, new_value)

    {:noreply, assign(socket, :social_settings, updated_settings)}
  end

  @impl true
  def handle_event("toggle_weekly_digest", _params, socket) do
    new_value = !socket.assigns.social_settings.weekly_digest
    updated_settings = Map.put(socket.assigns.social_settings, :weekly_digest, new_value)
    {:noreply, assign(socket, :social_settings, updated_settings)}
  end

  @impl true
  def handle_event("toggle_adult_content_filter", _params, socket) do
    new_value = !socket.assigns.social_settings.adult_content_filter
    updated_settings = Map.put(socket.assigns.social_settings, :adult_content_filter, new_value)
    {:noreply, assign(socket, :social_settings, updated_settings)}
  end

  @impl true
  def handle_event("navigate_to_lists", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/listas")}
  end

  @impl true
  def handle_event("navigate_to_profile", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/perfil")}
  end

  def handle_event("go_back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/perfil")}
  end

  # Private functions

  defp get_privacy_settings(user) do
    %{
      public_profile: user.public_profile || false,
      show_activity: user.show_activity || false,
      allow_messages: user.allow_messages || false
    }
  end

  defp get_social_settings(user) do
    %{
      follower_notifications: user.follower_notifications || false,
      share_lists: user.share_lists || false,
      social_recommendations: user.social_recommendations || false
    }
  end

  defp get_user_statistics(user) do
    case user do
      nil ->
        %{
          watched_movies_count: 0,
          watched_tv_shows_count: 0,
          lists_count: 0,
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
        # Get statistics from UserTitle system
        watched_movies = get_user_title_count(user.id, :watched, "movie")
        watched_tv_shows = get_user_title_count(user.id, :watched, "tv")
        lists_count = get_user_lists_count(user.id)
        average_rating = get_user_average_rating(user.id)
        total_ratings = get_user_ratings_count(user.id)

        %{
          watched_movies_count: watched_movies,
          watched_tv_shows_count: watched_tv_shows,
          lists_count: lists_count,
          total_watched: watched_movies + watched_tv_shows,
          total_watching: get_user_title_count(user.id, :watching, nil),
          total_want_to_watch: get_user_title_count(user.id, :want_to_watch, nil),
          total_favorites: get_user_title_count(user.id, :favorite, nil),
          time_spent: calculate_time_spent(watched_movies + watched_tv_shows),
          top_genre: get_top_genre(user),
          average_rating: average_rating,
          total_ratings: total_ratings
        }
    end
  end

  defp get_user_title_count(user_id, status, media_type) do
    alias Javi.Media.{UserTitle, Title}

    query = UserTitle |> where([ut], ut.user_id == ^user_id and ut.status == ^status)

    query =
      if media_type do
        query
        |> join(:inner, [ut], t in Title, on: ut.title_id == t.id)
        |> where([ut, t], t.tmdb_type == ^media_type)
      else
        query
      end

    Repo.aggregate(query, :count, :id) || 0
  end

  defp get_user_lists_count(user_id) do
    alias Javi.Accounts.List

    Repo.aggregate(List |> where([l], l.user_id == ^user_id), :count, :id) || 0
  end

  defp get_user_average_rating(user_id) do
    alias Javi.Media.UserTitle

    result =
      UserTitle
      |> where([ut], ut.user_id == ^user_id and not is_nil(ut.rating))
      |> select([ut], avg(ut.rating))
      |> Repo.one()

    case result do
      nil -> Decimal.new("0.0")
      avg_rating -> avg_rating
    end
  end

  defp get_user_ratings_count(user_id) do
    alias Javi.Media.UserTitle

    Repo.aggregate(
      UserTitle |> where([ut], ut.user_id == ^user_id and not is_nil(ut.rating)),
      :count,
      :id
    ) || 0
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
