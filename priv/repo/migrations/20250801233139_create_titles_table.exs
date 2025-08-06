defmodule Javi.Repo.Migrations.CreateTitlesTable do
  use Ecto.Migration

  def change do
    create table(:titles) do
      add :tmdb_id, :integer, null: false
      # "movie" or "tv"
      add :tmdb_type, :string, null: false
      add :title, :string, null: false
      add :original_title, :string
      add :overview, :text
      add :release_date, :date
      add :first_air_date, :date
      add :vote_average, :decimal, precision: 3, scale: 1
      add :vote_count, :integer
      add :popularity, :decimal, precision: 10, scale: 2
      add :poster_path, :string
      add :backdrop_path, :string
      add :adult, :boolean, default: false
      add :genres, {:array, :string}
      add :last_updated_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    # Unique constraint for TMDB ID and type combination
    create unique_index(:titles, [:tmdb_id, :tmdb_type], name: :titles_tmdb_id_tmdb_type_index)

    # Indexes for efficient querying
    create index(:titles, [:tmdb_type])
    create index(:titles, [:title])
    create index(:titles, [:vote_average])
    create index(:titles, [:popularity])
    create index(:titles, [:release_date])
    create index(:titles, [:first_air_date])
    create index(:titles, [:last_updated_at])
    create index(:titles, [:adult])

    # Full-text search index for title and overview
    execute "CREATE INDEX titles_search_idx ON titles USING gin(to_tsvector('english', title || ' ' || COALESCE(overview, '')))"

    # Index for array field (genres)
    execute "CREATE INDEX titles_genres_idx ON titles USING gin(genres)"
  end
end
