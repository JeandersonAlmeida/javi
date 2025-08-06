defmodule Javi.Media.Title do
  @moduledoc """
  Schema for storing TMDB title data locally to reduce API calls and improve performance.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "titles" do
    field :tmdb_id, :integer
    # "movie" or "tv"
    field :tmdb_type, :string
    field :title, :string
    field :original_title, :string
    field :overview, :string
    field :release_date, :date
    field :first_air_date, :date
    field :vote_average, :decimal
    field :vote_count, :integer
    field :popularity, :decimal
    field :poster_path, :string
    field :backdrop_path, :string
    field :adult, :boolean, default: false
    field :genres, {:array, :string}
    # Duration in minutes for movies
    field :runtime, :integer
    # Duration in minutes for TV episodes
    field :episode_run_time, {:array, :integer}
    # Number of seasons for TV shows
    field :number_of_seasons, :integer
    # Total number of episodes for TV shows
    field :number_of_episodes, :integer
    field :last_updated_at, :utc_datetime

    # Associations
    has_many :user_titles, Javi.Media.UserTitle
    has_many :users, through: [:user_titles, :user]

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for creating a new title.
  """
  def changeset(title, attrs) do
    title
    |> cast(attrs, [
      :tmdb_id,
      :tmdb_type,
      :title,
      :original_title,
      :overview,
      :release_date,
      :first_air_date,
      :vote_average,
      :vote_count,
      :popularity,
      :poster_path,
      :backdrop_path,
      :adult,
      :genres,
      :runtime,
      :episode_run_time,
      :number_of_seasons,
      :number_of_episodes
    ])
    |> validate_required([:tmdb_id, :tmdb_type, :title])
    |> validate_inclusion(:tmdb_type, ["movie", "tv"])
    |> validate_number(:vote_average, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
    |> validate_number(:vote_count, greater_than_or_equal_to: 0)
    |> validate_number(:popularity, greater_than_or_equal_to: 0)
    |> validate_number(:runtime, greater_than_or_equal_to: 0)
    |> validate_number(:number_of_seasons, greater_than_or_equal_to: 0)
    |> validate_number(:number_of_episodes, greater_than_or_equal_to: 0)
    |> unique_constraint([:tmdb_id, :tmdb_type], name: :titles_tmdb_id_tmdb_type_index)
    |> put_change(:last_updated_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Creates a changeset for updating an existing title.
  """
  def update_changeset(title, attrs) do
    title
    |> cast(attrs, [
      :title,
      :original_title,
      :overview,
      :release_date,
      :first_air_date,
      :vote_average,
      :vote_count,
      :popularity,
      :poster_path,
      :backdrop_path,
      :adult,
      :genres,
      :runtime,
      :episode_run_time,
      :number_of_seasons,
      :number_of_episodes
    ])
    |> validate_inclusion(:tmdb_type, ["movie", "tv"])
    |> validate_number(:vote_average, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
    |> validate_number(:vote_count, greater_than_or_equal_to: 0)
    |> validate_number(:popularity, greater_than_or_equal_to: 0)
    |> validate_number(:runtime, greater_than_or_equal_to: 0)
    |> validate_number(:number_of_seasons, greater_than_or_equal_to: 0)
    |> validate_number(:number_of_episodes, greater_than_or_equal_to: 0)
    |> put_change(:last_updated_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Finds a title by TMDB ID and type.
  """
  def get_by_tmdb_id(tmdb_id, tmdb_type) do
    from(t in __MODULE__,
      where: t.tmdb_id == ^tmdb_id and t.tmdb_type == ^tmdb_type
    )
  end

  @doc """
  Finds titles that need to be updated (older than specified hours).
  """
  def get_stale_titles(hours_ago) do
    cutoff_time = DateTime.add(DateTime.utc_now(), -hours_ago * 3600, :second)

    from(t in __MODULE__,
      where: t.last_updated_at < ^cutoff_time
    )
  end

  @doc """
  Searches titles by title or original title.
  """
  def search_titles(query) do
    search_term = "%#{query}%"

    from(t in __MODULE__,
      where: ilike(t.title, ^search_term) or ilike(t.original_title, ^search_term),
      order_by: [desc: t.popularity, desc: t.vote_average]
    )
  end

  @doc """
  Gets titles by type (movie or tv).
  """
  def get_by_type(tmdb_type) do
    from(t in __MODULE__,
      where: t.tmdb_type == ^tmdb_type,
      order_by: [desc: t.popularity, desc: t.vote_average]
    )
  end

  @doc """
  Gets titles by genre.
  """
  def get_by_genre(genre) do
    from(t in __MODULE__,
      where: ^genre in t.genres,
      order_by: [desc: t.popularity, desc: t.vote_average]
    )
  end

  @doc """
  Gets popular titles.
  """
  def get_popular_titles(limit \\ 20) do
    from(t in __MODULE__,
      order_by: [desc: t.popularity, desc: t.vote_average],
      limit: ^limit
    )
  end

  @doc """
  Gets highly rated titles.
  """
  def get_highly_rated_titles(limit \\ 20) do
    from(t in __MODULE__,
      where: t.vote_average >= 7.0 and t.vote_count >= 100,
      order_by: [desc: t.vote_average, desc: t.vote_count],
      limit: ^limit
    )
  end
end
