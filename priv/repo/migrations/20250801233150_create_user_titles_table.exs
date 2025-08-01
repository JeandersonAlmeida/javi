defmodule Javi.Repo.Migrations.CreateUserTitlesTable do
  use Ecto.Migration

  def change do
    create table(:user_titles) do
      # watching, watched, want_to_watch, favorite
      add :status, :string, null: false
      # 1-10 scale
      add :rating, :integer
      add :notes, :text
      add :date_watched, :date
      add :date_started, :date
      add :date_completed, :date
      # For TV shows
      add :episodes_watched, :integer
      # For TV shows
      add :total_episodes, :integer
      add :rewatch_count, :integer, default: 0
      add :is_private, :boolean, default: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :title_id, references(:titles, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # Unique constraint to prevent duplicate user-title combinations
    create unique_index(:user_titles, [:user_id, :title_id],
             name: :user_titles_user_id_title_id_index
           )

    # Indexes for efficient querying
    create index(:user_titles, [:user_id])
    create index(:user_titles, [:title_id])
    create index(:user_titles, [:status])
    create index(:user_titles, [:rating])
    create index(:user_titles, [:date_watched])
    create index(:user_titles, [:date_started])
    create index(:user_titles, [:date_completed])
    create index(:user_titles, [:is_private])
    create index(:user_titles, [:inserted_at])

    # Composite indexes for common queries
    create index(:user_titles, [:user_id, :status])
    create index(:user_titles, [:user_id, :rating])
    create index(:user_titles, [:user_id, :date_watched])
    create index(:user_titles, [:title_id, :status])

    # Check constraints
    execute "ALTER TABLE user_titles ADD CONSTRAINT user_titles_rating_check CHECK (rating >= 1 AND rating <= 10)"

    execute "ALTER TABLE user_titles ADD CONSTRAINT user_titles_episodes_watched_check CHECK (episodes_watched >= 0)"

    execute "ALTER TABLE user_titles ADD CONSTRAINT user_titles_total_episodes_check CHECK (total_episodes >= 0)"

    execute "ALTER TABLE user_titles ADD CONSTRAINT user_titles_rewatch_count_check CHECK (rewatch_count >= 0)"

    execute "ALTER TABLE user_titles ADD CONSTRAINT user_titles_episodes_watched_vs_total_check CHECK (episodes_watched <= total_episodes OR episodes_watched IS NULL OR total_episodes IS NULL)"
  end
end
