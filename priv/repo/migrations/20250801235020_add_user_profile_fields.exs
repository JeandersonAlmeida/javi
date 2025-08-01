defmodule Javi.Repo.Migrations.AddUserProfileFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Profile information
      add :display_name, :string
      add :bio, :text
      add :avatar_url, :string

      # Preferences and settings
      add :preferred_language, :string, default: "pt-BR"
      add :timezone, :string, default: "America/Sao_Paulo"
      add :date_format, :string, default: "DD/MM/YYYY"
      # 5 or 10 point scale
      add :rating_scale, :integer, default: 10

      # Privacy settings
      # public, friends, private
      add :profile_visibility, :string, default: "public"
      add :show_ratings, :boolean, default: true
      add :show_watchlist, :boolean, default: true
      add :show_favorites, :boolean, default: true
      add :show_watching, :boolean, default: true
      add :show_watched, :boolean, default: true

      # Notification preferences
      add :email_notifications, :boolean, default: true
      add :new_releases_notifications, :boolean, default: true
      add :friend_activity_notifications, :boolean, default: true
      add :weekly_digest, :boolean, default: true

      # Content preferences
      add :preferred_genres, {:array, :string}
      add :excluded_genres, {:array, :string}
      add :adult_content_filter, :boolean, default: true
      # Minimum rating to show
      add :min_rating_filter, :integer, default: 0

      # Social features
      add :allow_friend_requests, :boolean, default: true
      add :auto_accept_friends, :boolean, default: false

      # Activity tracking
      add :last_activity_at, :utc_datetime
      add :total_watched, :integer, default: 0
      add :total_watching, :integer, default: 0
      add :total_want_to_watch, :integer, default: 0
      add :total_favorites, :integer, default: 0
      add :average_rating, :decimal, precision: 3, scale: 1
      add :total_ratings_given, :integer, default: 0

      # Account settings
      # active, suspended, deleted
      add :account_status, :string, default: "active"
      add :deleted_at, :utc_datetime
    end

    # Indexes for performance
    create index(:users, [:display_name])
    create index(:users, [:profile_visibility])
    create index(:users, [:last_activity_at])
    create index(:users, [:account_status])
    create index(:users, [:preferred_language])
    create index(:users, [:timezone])

    # Full-text search index for display name and bio
    execute "CREATE INDEX users_search_idx ON users USING gin(to_tsvector('english', COALESCE(display_name, '') || ' ' || COALESCE(bio, '')))"

    # Index for array fields
    execute "CREATE INDEX users_preferred_genres_idx ON users USING gin(preferred_genres)"
    execute "CREATE INDEX users_excluded_genres_idx ON users USING gin(excluded_genres)"
  end
end
