defmodule JaviWeb.Home.TitleDetailLive do
  use JaviWeb, :live_view

  alias Javi.Media
  import JaviWeb.Components.BottomNavigation
  import JaviWeb.Helpers.GenreHelper

  @impl true
  def mount(%{"id" => id, "referrer" => referrer}, _session, socket) do
    user = socket.assigns.current_user

    # Try to get title by database ID first, then by TMDB ID
    title =
      case Integer.parse(id) do
        {db_id, ""} -> Media.get_title(db_id)
        _ -> nil
      end

    # If not found by database ID, try by TMDB ID
    title = if is_nil(title), do: Media.get_title_by_tmdb_id(id, nil), else: title

    case title do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/pesquisar")}

      title ->
        # Check if title is in user's watched list (via Lists)
        is_in_watched = if user, do: is_in_watched_list?(user, title), else: false

        # Get user's rating from watched list item if present
        user_rating = if user && is_in_watched, do: get_user_rating(user, title), else: nil

        # Get user's lists for the add to lists modal
        user_lists = if user, do: Javi.Accounts.get_user_lists(user), else: []

        # Get title lists for display
        title_lists = if user, do: get_title_lists(user, title), else: []

        socket =
          socket
          |> assign(:title, title)
          |> assign(:user, user)
          |> assign(:user_rating, user_rating)
          |> assign(:is_in_watched, is_in_watched)
          |> assign(:user_lists, user_lists)
          |> assign(:title_lists, title_lists)
          |> assign(:show_modal, false)
          |> assign(:selected_title, nil)
          |> assign(:selected_lists, [])
          |> assign(:referrer, referrer)
          |> assign(:current_page, :title_detail)

        {:ok, socket}
    end
  end

  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user

    # Try to get title by database ID first, then by TMDB ID
    title =
      case Integer.parse(id) do
        {db_id, ""} -> Media.get_title(db_id)
        _ -> nil
      end

    # If not found by database ID, try by TMDB ID
    title = if is_nil(title), do: Media.get_title_by_tmdb_id(id, nil), else: title

    case title do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/pesquisar")}

      title ->
        # Check if title is in user's watched list (via Lists)
        is_in_watched = if user, do: is_in_watched_list?(user, title), else: false

        # Get user's rating from watched list item if present
        user_rating = if user && is_in_watched, do: get_user_rating(user, title), else: nil

        # Get user's lists for the add to lists modal
        user_lists = if user, do: Javi.Accounts.get_user_lists(user), else: []

        # Get title lists for display
        title_lists = if user, do: get_title_lists(user, title), else: []

        socket =
          socket
          |> assign(:title, title)
          |> assign(:user, user)
          |> assign(:user_rating, user_rating)
          |> assign(:is_in_watched, is_in_watched)
          |> assign(:user_lists, user_lists)
          |> assign(:title_lists, title_lists)
          |> assign(:show_modal, false)
          |> assign(:selected_title, nil)
          |> assign(:selected_lists, [])
          |> assign(:referrer, "search")
          |> assign(:current_page, :title_detail)

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("go_back", _params, socket) do
    referrer = socket.assigns.referrer || "search"

    case referrer do
      "search" -> {:noreply, push_navigate(socket, to: ~p"/pesquisar")}
      "lists" -> {:noreply, push_navigate(socket, to: ~p"/listas")}
      "dashboard" -> {:noreply, push_navigate(socket, to: ~p"/inicio")}
      _ -> {:noreply, push_navigate(socket, to: ~p"/pesquisar")}
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

        # Refresh title lists after adding
        title_lists = get_title_lists(user, socket.assigns.title)

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> assign(:show_modal, false)
         |> assign(:selected_title, nil)
         |> assign(:selected_lists, [])
         |> assign(:title_lists, title_lists)}
    end
  end

  @impl true
  def handle_event("rate_title", %{"rating" => rating}, socket) do
    user = socket.assigns.user
    title = socket.assigns.title

    case user do
      nil ->
        {:noreply, socket}

      _user ->
        case Integer.parse(rating) do
          {rating_int, _} when rating_int >= 1 and rating_int <= 5 ->
            case Media.update_watched_list_item_rating(user, title.id, rating_int) do
              {:ok, _list_item} ->
                {:noreply, assign(socket, user_rating: rating_int)}

              {:error, _} ->
                {:noreply, socket}
            end

          _ ->
            {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_event("add_to_watched", _params, socket) do
    case socket.assigns.user do
      nil ->
        {:noreply, socket}

      user ->
        title = socket.assigns.title

        # Build a TMDB-like map from the current DB title to reuse Media.add_title_to_watched_list/2
        title_data = %{
          "id" => title.tmdb_id,
          "title" => title.title,
          "name" => title.title,
          "overview" => title.overview,
          "release_date" => title.release_date,
          "first_air_date" => title.first_air_date,
          "vote_average" => title.vote_average,
          "vote_count" => title.vote_count,
          "popularity" => title.popularity,
          "poster_path" => title.poster_path,
          "backdrop_path" => title.backdrop_path,
          "adult" => title.adult,
          "genre_ids" => title.genres,
          "media_type" => title.tmdb_type,
          "runtime" => title.runtime,
          "episode_run_time" => title.episode_run_time,
          "number_of_seasons" => title.number_of_seasons,
          "number_of_episodes" => title.number_of_episodes
        }

        case Media.add_title_to_watched_list(user, title_data) do
          {:ok, _list_item} ->
            # Update assigns: now in watched, show rating UI tied to list item rating
            socket =
              socket
              |> assign(:is_in_watched, true)
              |> assign(:user_rating, get_user_rating(user, title))
              |> assign(:title_lists, get_title_lists(user, title))

            {:noreply, socket}

          {:error, _} ->
            {:noreply, socket}
        end
    end
  end

  # Private functions

  defp get_user_rating(user, title) do
    case Media.get_watched_list_item_by_title_id(user, title.id) do
      nil -> nil
      list_item -> list_item.rating
    end
  end

  defp is_in_watched_list?(user, title) do
    not is_nil(Media.get_watched_list_item_by_title_id(user, title.id))
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

  defp get_title_lists(user, title) do
    case user do
      nil ->
        []

      user ->
        # Get all user lists and filter those that contain this title
        user_lists = Javi.Accounts.get_user_lists(user)

        Enum.filter(user_lists, fn list ->
          Enum.any?(list.list_items || [], fn item ->
            item.title_id == title.id
          end)
        end)
    end
  end
end
