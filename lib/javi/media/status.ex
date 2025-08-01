defmodule Javi.Media.Status do
  @moduledoc """
  Helper module for handling user title statuses and related utilities.
  """

  @statuses [:watching, :watched, :want_to_watch, :favorite]

  @doc """
  Returns all available statuses.
  """
  def all_statuses, do: @statuses

  @doc """
  Returns statuses as strings.
  """
  def status_strings do
    @statuses
    |> Enum.map(&Atom.to_string/1)
  end

  @doc """
  Returns statuses with their display names.
  """
  def status_display_names do
    [
      watching: "Watching",
      watched: "Watched",
      want_to_watch: "Want to Watch",
      favorite: "Favorite"
    ]
  end

  @doc """
  Gets the display name for a status.
  """
  def display_name(status) when is_atom(status) do
    status_display_names()
    |> Keyword.get(status, Atom.to_string(status))
  end

  @doc """
  Converts a string status to an atom.
  """
  def to_atom(status) when is_binary(status) do
    case String.to_existing_atom(status) do
      atom when atom in @statuses -> atom
      _ -> nil
    end
  end

  @doc """
  Validates if a status is valid.
  """
  def valid_status?(status) when is_atom(status) do
    status in @statuses
  end

  def valid_status?(_), do: false

  @doc """
  Returns statuses that can be combined with favorites.
  """
  def combinable_with_favorite do
    [:watching, :watched, :want_to_watch]
  end

  @doc """
  Checks if a status can be combined with favorite.
  """
  def can_combine_with_favorite?(status) do
    status in combinable_with_favorite()
  end

  @doc """
  Returns the icon class for a status.
  """
  def icon_class(status) do
    case status do
      :watching -> "fas fa-play"
      :watched -> "fas fa-check"
      :want_to_watch -> "fas fa-clock"
      :favorite -> "fas fa-heart"
      _ -> "fas fa-question"
    end
  end

  @doc """
  Returns the color class for a status.
  """
  def color_class(status) do
    case status do
      :watching -> "text-blue-600"
      :watched -> "text-green-600"
      :want_to_watch -> "text-yellow-600"
      :favorite -> "text-red-600"
      _ -> "text-gray-600"
    end
  end

  @doc """
  Returns the background color class for a status.
  """
  def bg_color_class(status) do
    case status do
      :watching -> "bg-blue-100"
      :watched -> "bg-green-100"
      :want_to_watch -> "bg-yellow-100"
      :favorite -> "bg-red-100"
      _ -> "bg-gray-100"
    end
  end

  @doc """
  Returns statuses grouped by category.
  """
  def grouped_statuses do
    [
      primary: [:watching, :watched, :want_to_watch],
      special: [:favorite]
    ]
  end

  @doc """
  Returns the next logical status in a progression.
  """
  def next_status(current_status) do
    case current_status do
      :want_to_watch -> :watching
      :watching -> :watched
      # Stay watched
      :watched -> :watched
      # Stay favorite
      :favorite -> :favorite
      _ -> nil
    end
  end

  @doc """
  Returns the previous logical status in a progression.
  """
  def previous_status(current_status) do
    case current_status do
      :watched -> :watching
      :watching -> :want_to_watch
      # Stay want to watch
      :want_to_watch -> :want_to_watch
      # Stay favorite
      :favorite -> :favorite
      _ -> nil
    end
  end

  @doc """
  Returns statuses that can be set for movies.
  """
  def movie_statuses do
    [:watched, :want_to_watch, :favorite]
  end

  @doc """
  Returns statuses that can be set for TV shows.
  """
  def tv_statuses do
    [:watching, :watched, :want_to_watch, :favorite]
  end

  @doc """
  Returns appropriate statuses for a given media type.
  """
  def statuses_for_type("movie"), do: movie_statuses()
  def statuses_for_type("tv"), do: tv_statuses()
  def statuses_for_type(_), do: all_statuses()

  @doc """
  Returns a human-readable description of what each status means.
  """
  def status_description(status) do
    case status do
      :watching -> "Currently watching this title"
      :watched -> "Have watched this title"
      :want_to_watch -> "Want to watch this title"
      :favorite -> "This is one of my favorite titles"
      _ -> "Unknown status"
    end
  end

  @doc """
  Returns statuses that can be used for filtering.
  """
  def filter_statuses do
    [
      all: "All",
      watching: "Watching",
      watched: "Watched",
      want_to_watch: "Want to Watch",
      favorite: "Favorites"
    ]
  end
end
