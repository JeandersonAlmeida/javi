defmodule Javi.MediaFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Javi.Media` context.
  """

  alias Javi.Media

  @doc """
  Generate a title.
  """
  def title_fixture(attrs \\ %{}) do
    # Generate a unique tmdb_id to avoid constraint violations (using smaller range for database compatibility)
    unique_id =
      :crypto.strong_rand_bytes(2)
      |> Base.encode16(case: :lower)
      |> binary_part(0, 4)
      |> String.to_integer(16)
      |> Kernel.+(1000)

    {:ok, title} =
      attrs
      |> Enum.into(%{
        tmdb_id: unique_id,
        tmdb_type: "movie",
        title: "Test Movie",
        original_title: "Test Movie",
        overview: "A test movie for testing purposes",
        release_date: ~D[2024-01-01],
        vote_average: Decimal.new("7.5"),
        vote_count: 1000,
        popularity: Decimal.new("85.5"),
        poster_path: "/test-poster.jpg",
        backdrop_path: "/test-backdrop.jpg",
        adult: false,
        genres: ["Action", "Adventure"],
        runtime: 120,
        episode_run_time: nil,
        number_of_seasons: nil,
        number_of_episodes: nil
      })
      |> Media.create_title()

    title
  end

  @doc """
  Generate a user_title.
  """
  def user_title_fixture(attrs \\ %{}) do
    {:ok, user_title} =
      attrs
      |> Enum.into(%{
        user_id: 1,
        title_id: 1,
        status: "watching"
      })
      |> Media.create_user_title()

    user_title
  end
end
