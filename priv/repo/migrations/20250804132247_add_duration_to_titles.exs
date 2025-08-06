defmodule Javi.Repo.Migrations.AddDurationToTitles do
  use Ecto.Migration

  def change do
    alter table(:titles) do
      # Duration in minutes for movies
      add :runtime, :integer
      # Duration in minutes for TV episodes
      add :episode_run_time, {:array, :integer}
      # Number of seasons for TV shows
      add :number_of_seasons, :integer
      # Total number of episodes for TV shows
      add :number_of_episodes, :integer
    end
  end
end
