defmodule Javi.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime

    # Profile information
    field :display_name, :string
    field :bio, :string
    field :avatar_url, :string
    field :photo_url, :string

    # Preferences and settings
    field :preferred_language, :string, default: "pt-BR"
    field :timezone, :string, default: "America/Sao_Paulo"
    field :date_format, :string, default: "DD/MM/YYYY"
    field :rating_scale, :integer, default: 10

    # Privacy settings
    field :profile_visibility, :string, default: "public"
    field :show_ratings, :boolean, default: true
    field :show_watchlist, :boolean, default: true
    field :show_favorites, :boolean, default: true
    field :show_watching, :boolean, default: true
    field :show_watched, :boolean, default: true
    field :public_profile, :boolean, default: true
    field :show_activity, :boolean, default: true
    field :allow_messages, :boolean, default: true

    # Notification preferences
    field :email_notifications, :boolean, default: true
    field :new_releases_notifications, :boolean, default: true
    field :friend_activity_notifications, :boolean, default: true
    field :weekly_digest, :boolean, default: true

    # Content preferences
    field :preferred_genres, {:array, :string}
    field :excluded_genres, {:array, :string}
    field :adult_content_filter, :boolean, default: true
    field :min_rating_filter, :integer, default: 0

    # Social features
    field :allow_friend_requests, :boolean, default: true
    field :auto_accept_friends, :boolean, default: false
    field :follower_notifications, :boolean, default: true
    field :share_lists, :boolean, default: true
    field :social_recommendations, :boolean, default: true

    # Activity tracking
    field :last_activity_at, :utc_datetime
    field :total_watched, :integer, default: 0
    field :total_watching, :integer, default: 0
    field :total_want_to_watch, :integer, default: 0
    field :total_favorites, :integer, default: 0
    field :average_rating, :decimal
    field :total_ratings_given, :integer, default: 0

    # Account settings
    field :account_status, :string, default: "active"
    field :deleted_at, :utc_datetime

    # Onboarding
    field :onboarding_completed, :boolean, default: false

    # Associations
    has_many :user_titles, Javi.Media.UserTitle
    has_many :titles, through: [:user_titles, :title]
    has_many :lists, Javi.Accounts.List

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :display_name])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_display_name()
    |> put_change(:onboarding_completed, false)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp validate_display_name(changeset) do
    changeset
    |> validate_required([:display_name])
    |> validate_length(:display_name, min: 2, max: 50)
    |> validate_format(:display_name, ~r/^[a-zA-ZÀ-ÿ\s]+$/,
      message: "must contain only letters and spaces"
    )
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Javi.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Javi.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  A user changeset for updating profile information.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :display_name,
      :bio,
      :avatar_url,
      :preferred_language,
      :timezone,
      :date_format,
      :rating_scale,
      :profile_visibility,
      :show_ratings,
      :show_watchlist,
      :show_favorites,
      :show_watching,
      :show_watched,
      :email_notifications,
      :new_releases_notifications,
      :friend_activity_notifications,
      :weekly_digest,
      :preferred_genres,
      :excluded_genres,
      :adult_content_filter,
      :min_rating_filter,
      :allow_friend_requests,
      :auto_accept_friends
    ])
    |> validate_length(:display_name, max: 50)
    |> validate_length(:bio, max: 500)
    |> validate_inclusion(:profile_visibility, ["public", "friends", "private"])
    |> validate_inclusion(:rating_scale, [5, 10])
    |> validate_number(:min_rating_filter, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
    |> validate_preferred_genres()
    |> validate_excluded_genres()
    |> put_change(:last_activity_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  A user changeset for updating privacy settings.
  """
  def privacy_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :profile_visibility,
      :show_ratings,
      :show_watchlist,
      :show_favorites,
      :show_watching,
      :show_watched,
      :allow_friend_requests,
      :auto_accept_friends
    ])
    |> validate_inclusion(:profile_visibility, ["public", "friends", "private"])
  end

  @doc """
  A user changeset for updating privacy settings with new fields.
  """
  def privacy_settings_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :public_profile,
      :show_activity,
      :allow_messages
    ])
  end

  @doc """
  A user changeset for updating social settings.
  """
  def social_settings_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :follower_notifications,
      :share_lists,
      :social_recommendations
    ])
  end

  @doc """
  A user changeset for updating photo.
  """
  def photo_changeset(user, attrs) do
    user
    |> cast(attrs, [:photo_url])
    |> validate_format(:photo_url, ~r/^https?:\/\//, message: "must be a valid URL")
  end

  @doc """
  A user changeset for updating notification preferences.
  """
  def notification_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email_notifications,
      :new_releases_notifications,
      :friend_activity_notifications,
      :weekly_digest
    ])
  end

  @doc """
  A user changeset for updating content preferences.
  """
  def content_preferences_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :preferred_genres,
      :excluded_genres,
      :adult_content_filter,
      :min_rating_filter
    ])
    |> validate_number(:min_rating_filter, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
    |> validate_preferred_genres()
    |> validate_excluded_genres()
  end

  @doc """
  A user changeset for updating activity statistics.
  """
  def activity_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :total_watched,
      :total_watching,
      :total_want_to_watch,
      :total_favorites,
      :average_rating,
      :total_ratings_given,
      :last_activity_at
    ])
    |> validate_number(:total_watched, greater_than_or_equal_to: 0)
    |> validate_number(:total_watching, greater_than_or_equal_to: 0)
    |> validate_number(:total_want_to_watch, greater_than_or_equal_to: 0)
    |> validate_number(:total_favorites, greater_than_or_equal_to: 0)
    |> validate_number(:total_ratings_given, greater_than_or_equal_to: 0)
    |> validate_number(:average_rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
  end

  @doc """
  A user changeset for soft deletion.
  """
  def soft_delete_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    user
    |> change(account_status: "deleted", deleted_at: now)
  end

  @doc """
  A user changeset for reactivating a deleted account.
  """
  def reactivate_changeset(user) do
    user
    |> change(account_status: "active", deleted_at: nil)
  end

  @doc """
  Updates user activity timestamp.
  """
  def update_activity_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, last_activity_at: now)
  end

  @doc """
  Creates default lists for a new user.
  """
  def create_default_lists(%Javi.Accounts.User{} = user) do
    default_lists = [
      %{
        name: "Assistidos",
        description: "Filmes e séries que você já assistiu",
        list_type: "watched",
        is_public: false
      },
      %{
        name: "Assistindo",
        description: "Filmes e séries que você está assistindo",
        list_type: "watching",
        is_public: false
      },
      %{
        name: "Favoritos",
        description: "Seus filmes e séries favoritos",
        list_type: "favorites",
        is_public: false
      }
    ]

    Enum.each(default_lists, fn list_attrs ->
      Javi.Accounts.create_list(user, list_attrs)
    end)
  end

  @doc """
  Gets default lists for a user.
  """
  def get_default_lists(%Javi.Accounts.User{} = user) do
    Javi.Accounts.get_user_lists(user)
    |> Enum.filter(fn list ->
      list.list_type in ["watched", "watching", "favorites"]
    end)
  end

  @doc """
  Marks onboarding as completed for a user.
  """
  def complete_onboarding_changeset(user) do
    change(user, onboarding_completed: true)
  end

  # Private functions

  defp validate_preferred_genres(changeset) do
    case get_change(changeset, :preferred_genres) do
      nil ->
        changeset

      genres when is_list(genres) ->
        if Enum.all?(genres, &is_binary/1) do
          changeset
        else
          add_error(changeset, :preferred_genres, "must be a list of strings")
        end

      _ ->
        add_error(changeset, :preferred_genres, "must be a list")
    end
  end

  defp validate_excluded_genres(changeset) do
    case get_change(changeset, :excluded_genres) do
      nil ->
        changeset

      genres when is_list(genres) ->
        if Enum.all?(genres, &is_binary/1) do
          changeset
        else
          add_error(changeset, :excluded_genres, "must be a list of strings")
        end

      _ ->
        add_error(changeset, :excluded_genres, "must be a list")
    end
  end
end
