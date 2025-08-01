defmodule Javi.Media.UserTitle do
  @moduledoc """
  Schema for tracking user interactions with titles (movies and TV shows).
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "user_titles" do
    field :status, Ecto.Enum,
      values: [:watching, :watched, :want_to_watch, :favorite],
      null: false

    # 1-10 scale
    field :rating, :integer
    field :notes, :string
    field :date_watched, :date
    field :date_started, :date
    field :date_completed, :date
    # For TV shows
    field :episodes_watched, :integer
    # For TV shows
    field :total_episodes, :integer
    field :rewatch_count, :integer, default: 0
    field :is_private, :boolean, default: false

    # Associations
    belongs_to :user, Javi.Accounts.User
    belongs_to :title, Javi.Media.Title

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for creating a new user title interaction.
  """
  def changeset(user_title, attrs) do
    user_title
    |> cast(attrs, [
      :status,
      :rating,
      :notes,
      :date_watched,
      :date_started,
      :date_completed,
      :episodes_watched,
      :total_episodes,
      :rewatch_count,
      :is_private,
      :user_id,
      :title_id
    ])
    |> validate_required([:status, :user_id, :title_id])
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
    |> validate_number(:episodes_watched, greater_than_or_equal_to: 0)
    |> validate_number(:total_episodes, greater_than_or_equal_to: 0)
    |> validate_number(:rewatch_count, greater_than_or_equal_to: 0)
    |> validate_episodes_watched()
    |> validate_dates()
    |> unique_constraint([:user_id, :title_id], name: :user_titles_user_id_title_id_index)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:title_id)
  end

  @doc """
  Creates a changeset for updating an existing user title interaction.
  """
  def update_changeset(user_title, attrs) do
    user_title
    |> cast(attrs, [
      :status,
      :rating,
      :notes,
      :date_watched,
      :date_started,
      :date_completed,
      :episodes_watched,
      :total_episodes,
      :rewatch_count,
      :is_private
    ])
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
    |> validate_number(:episodes_watched, greater_than_or_equal_to: 0)
    |> validate_number(:total_episodes, greater_than_or_equal_to: 0)
    |> validate_number(:rewatch_count, greater_than_or_equal_to: 0)
    |> validate_episodes_watched()
    |> validate_dates()
  end

  @doc """
  Creates a changeset for marking a title as watched.
  """
  def watched_changeset(user_title, attrs) do
    user_title
    |> cast(attrs, [:rating, :notes, :date_watched, :rewatch_count, :is_private])
    |> put_change(:status, :watched)
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
    |> validate_number(:rewatch_count, greater_than_or_equal_to: 0)
    |> validate_required([:date_watched])
  end

  @doc """
  Creates a changeset for marking a title as watching.
  """
  def watching_changeset(user_title, attrs) do
    user_title
    |> cast(attrs, [:episodes_watched, :total_episodes, :notes, :date_started, :is_private])
    |> put_change(:status, :watching)
    |> validate_number(:episodes_watched, greater_than_or_equal_to: 0)
    |> validate_number(:total_episodes, greater_than_or_equal_to: 0)
    |> validate_episodes_watched()
  end

  @doc """
  Creates a changeset for marking a title as want to watch.
  """
  def want_to_watch_changeset(user_title, attrs) do
    user_title
    |> cast(attrs, [:notes, :is_private])
    |> put_change(:status, :want_to_watch)
  end

  @doc """
  Creates a changeset for marking a title as favorite.
  """
  def favorite_changeset(user_title, attrs) do
    user_title
    |> cast(attrs, [:notes, :is_private])
    |> put_change(:status, :favorite)
  end

  @doc """
  Gets user titles by status.
  """
  def get_by_status(user_id, status) do
    from(ut in __MODULE__,
      where: ut.user_id == ^user_id and ut.status == ^status,
      preload: [:title],
      order_by: [desc: ut.inserted_at]
    )
  end

  @doc """
  Gets all user titles for a specific user.
  """
  def get_by_user(user_id) do
    from(ut in __MODULE__,
      where: ut.user_id == ^user_id,
      preload: [:title],
      order_by: [desc: ut.inserted_at]
    )
  end

  @doc """
  Gets user title by user and title IDs.
  """
  def get_by_user_and_title(user_id, title_id) do
    from(ut in __MODULE__,
      where: ut.user_id == ^user_id and ut.title_id == ^title_id,
      preload: [:title]
    )
  end

  @doc """
  Gets user titles with ratings.
  """
  def get_with_ratings(user_id) do
    from(ut in __MODULE__,
      where: ut.user_id == ^user_id and not is_nil(ut.rating),
      preload: [:title],
      order_by: [desc: ut.rating, desc: ut.inserted_at]
    )
  end

  @doc """
  Gets recently watched titles.
  """
  def get_recently_watched(user_id, limit \\ 10) do
    from(ut in __MODULE__,
      where: ut.user_id == ^user_id and ut.status == :watched,
      preload: [:title],
      order_by: [desc: ut.date_watched, desc: ut.inserted_at],
      limit: ^limit
    )
  end

  @doc """
  Gets user's favorite titles.
  """
  def get_favorites(user_id) do
    from(ut in __MODULE__,
      where: ut.user_id == ^user_id and ut.status == :favorite,
      preload: [:title],
      order_by: [desc: ut.inserted_at]
    )
  end

  @doc """
  Gets user's watching list.
  """
  def get_watching(user_id) do
    from(ut in __MODULE__,
      where: ut.user_id == ^user_id and ut.status == :watching,
      preload: [:title],
      order_by: [desc: ut.inserted_at]
    )
  end

  @doc """
  Gets user's want to watch list.
  """
  def get_want_to_watch(user_id) do
    from(ut in __MODULE__,
      where: ut.user_id == ^user_id and ut.status == :want_to_watch,
      preload: [:title],
      order_by: [desc: ut.inserted_at]
    )
  end

  @doc """
  Gets user's statistics.
  """
  def get_user_stats(user_id) do
    from(ut in __MODULE__,
      where: ut.user_id == ^user_id,
      select: %{
        total_watched: fragment("COUNT(CASE WHEN status = 'watched' THEN 1 END)"),
        total_watching: fragment("COUNT(CASE WHEN status = 'watching' THEN 1 END)"),
        total_want_to_watch: fragment("COUNT(CASE WHEN status = 'want_to_watch' THEN 1 END)"),
        total_favorites: fragment("COUNT(CASE WHEN status = 'favorite' THEN 1 END)"),
        average_rating: fragment("AVG(CASE WHEN rating IS NOT NULL THEN rating END)"),
        total_episodes_watched:
          fragment("SUM(CASE WHEN episodes_watched IS NOT NULL THEN episodes_watched ELSE 0 END)")
      }
    )
  end

  # Private functions

  defp validate_episodes_watched(changeset) do
    episodes_watched = get_field(changeset, :episodes_watched)
    total_episodes = get_field(changeset, :total_episodes)

    cond do
      is_nil(episodes_watched) or is_nil(total_episodes) ->
        changeset

      episodes_watched > total_episodes ->
        add_error(changeset, :episodes_watched, "cannot be greater than total episodes")

      true ->
        changeset
    end
  end

  defp validate_dates(changeset) do
    date_watched = get_field(changeset, :date_watched)
    date_started = get_field(changeset, :date_started)
    date_completed = get_field(changeset, :date_completed)

    cond do
      not is_nil(date_started) and not is_nil(date_completed) and
          Date.compare(date_started, date_completed) == :gt ->
        add_error(changeset, :date_completed, "cannot be before start date")

      not is_nil(date_watched) and not is_nil(date_started) and
          Date.compare(date_watched, date_started) == :lt ->
        add_error(changeset, :date_watched, "cannot be before start date")

      true ->
        changeset
    end
  end
end
