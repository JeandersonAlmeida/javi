defmodule Javi.Media.TitleTest do
  use Javi.DataCase

  alias Javi.Media.Title

  @valid_attrs %{
    tmdb_id: 123,
    tmdb_type: "movie",
    title: "Test Movie",
    original_title: "Test Movie Original",
    overview: "A test movie overview",
    release_date: ~D[2023-01-01],
    vote_average: Decimal.new("8.5"),
    vote_count: 1000,
    popularity: Decimal.new("85.5"),
    poster_path: "/test-poster.jpg",
    backdrop_path: "/test-backdrop.jpg",
    adult: false,
    genres: ["Action", "Drama"]
  }

  @invalid_attrs %{
    tmdb_id: nil,
    tmdb_type: nil,
    title: nil
  }

  describe "changeset/2" do
    test "changeset with valid attributes" do
      changeset = Title.changeset(%Title{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Title.changeset(%Title{}, @invalid_attrs)
      refute changeset.valid?
    end

    test "changeset validates required fields" do
      changeset = Title.changeset(%Title{}, %{})

      assert %{
               tmdb_id: ["can't be blank"],
               tmdb_type: ["can't be blank"],
               title: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "changeset validates tmdb_type inclusion" do
      changeset = Title.changeset(%Title{}, Map.put(@valid_attrs, :tmdb_type, "invalid"))
      assert %{tmdb_type: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates vote_average range" do
      changeset =
        Title.changeset(%Title{}, Map.put(@valid_attrs, :vote_average, Decimal.new("11.0")))

      assert %{vote_average: ["must be less than or equal to 10"]} = errors_on(changeset)

      changeset =
        Title.changeset(%Title{}, Map.put(@valid_attrs, :vote_average, Decimal.new("-1.0")))

      assert %{vote_average: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset validates vote_count" do
      changeset = Title.changeset(%Title{}, Map.put(@valid_attrs, :vote_count, -1))
      assert %{vote_count: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset validates popularity" do
      changeset =
        Title.changeset(%Title{}, Map.put(@valid_attrs, :popularity, Decimal.new("-1.0")))

      assert %{popularity: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset sets last_updated_at" do
      changeset = Title.changeset(%Title{}, @valid_attrs)
      assert get_change(changeset, :last_updated_at)
    end
  end

  describe "update_changeset/2" do
    test "update_changeset with valid attributes" do
      title = %Title{}
      changeset = Title.update_changeset(title, %{title: "Updated Title"})
      assert changeset.valid?
    end

    test "update_changeset validates vote_average range" do
      title = %Title{}
      changeset = Title.update_changeset(title, %{vote_average: Decimal.new("11.0")})
      assert %{vote_average: ["must be less than or equal to 10"]} = errors_on(changeset)
    end
  end

  describe "get_by_tmdb_id/2" do
    test "returns query for tmdb_id and tmdb_type" do
      query = Title.get_by_tmdb_id(123, "movie")
      assert query.from.source == {"titles", Title}
    end
  end

  describe "get_stale_titles/1" do
    test "returns query for stale titles" do
      query = Title.get_stale_titles(24)
      assert query.from.source == {"titles", Title}
    end
  end

  describe "search_titles/1" do
    test "returns query for title search" do
      query = Title.search_titles("test")
      assert query.from.source == {"titles", Title}
    end
  end

  describe "get_by_type/1" do
    test "returns query for titles by type" do
      query = Title.get_by_type("movie")
      assert query.from.source == {"titles", Title}
    end
  end

  describe "get_by_genre/1" do
    test "returns query for titles by genre" do
      query = Title.get_by_genre("Action")
      assert query.from.source == {"titles", Title}
    end
  end

  describe "get_popular_titles/1" do
    test "returns query for popular titles" do
      query = Title.get_popular_titles(10)
      assert query.from.source == {"titles", Title}
    end
  end

  describe "get_highly_rated_titles/1" do
    test "returns query for highly rated titles" do
      query = Title.get_highly_rated_titles(10)
      assert query.from.source == {"titles", Title}
    end
  end
end
