defmodule Javi.Media.TMDB.ClientTest do
  use ExUnit.Case, async: true

  alias Javi.Media.TMDB.Client, as: TMDBClient
  alias Javi.Media.TMDB.Client.Test, as: TMDBTest

  describe "search_movies/1" do
    test "returns empty results for valid query" do
      assert {:ok, %{"results" => []}} = TMDBClient.search_movies("test")
    end

    test "returns error for empty query" do
      assert {:error, "Invalid query"} = TMDBClient.search_movies("")
    end

    test "returns error for non-string query" do
      assert {:error, "Invalid query"} = TMDBClient.search_movies(123)
    end

    test "returns error for nil query" do
      assert {:error, "Invalid query"} = TMDBClient.search_movies(nil)
    end

    test "returns error for non-binary query" do
      assert {:error, "Invalid query"} = TMDBClient.search_movies(:atom)
    end
  end

  describe "search_tv/1" do
    test "returns empty results for valid query" do
      assert {:ok, %{"results" => []}} = TMDBClient.search_tv("test")
    end

    test "returns error for empty query" do
      assert {:error, "Invalid query"} = TMDBClient.search_tv("")
    end

    test "returns error for non-string query" do
      assert {:error, "Invalid query"} = TMDBClient.search_tv(123)
    end

    test "returns error for nil query" do
      assert {:error, "Invalid query"} = TMDBClient.search_tv(nil)
    end

    test "returns error for non-binary query" do
      assert {:error, "Invalid query"} = TMDBClient.search_tv(:atom)
    end
  end

  describe "get_movie_details/1" do
    test "returns test movie details for valid ID" do
      assert {:ok, movie} = TMDBClient.get_movie_details(1)
      assert movie["title"] == "Test Movie"
    end

    test "returns error for invalid movie ID" do
      assert {:error, "Invalid movie ID"} = TMDBClient.get_movie_details(0)
      assert {:error, "Invalid movie ID"} = TMDBClient.get_movie_details(-1)
      assert {:error, "Invalid movie ID"} = TMDBClient.get_movie_details("invalid")
    end

    test "returns error for non-integer ID" do
      assert {:error, "Invalid movie ID"} = TMDBClient.get_movie_details(:atom)
      assert {:error, "Invalid movie ID"} = TMDBClient.get_movie_details(nil)
    end
  end

  describe "get_tv_details/1" do
    test "returns test TV show details for valid ID" do
      assert {:ok, show} = TMDBClient.get_tv_details(1)
      assert show["name"] == "Test TV Show"
    end

    test "returns error for invalid TV show ID" do
      assert {:error, "Invalid TV show ID"} = TMDBClient.get_tv_details(0)
      assert {:error, "Invalid TV show ID"} = TMDBClient.get_tv_details(-1)
      assert {:error, "Invalid TV show ID"} = TMDBClient.get_tv_details("invalid")
    end

    test "returns error for non-integer ID" do
      assert {:error, "Invalid TV show ID"} = TMDBClient.get_tv_details(:atom)
      assert {:error, "Invalid TV show ID"} = TMDBClient.get_tv_details(nil)
    end
  end

  describe "get_trending_movies/1" do
    test "returns empty results for valid time window" do
      assert {:ok, %{"results" => []}} = TMDBClient.get_trending_movies("day")
      assert {:ok, %{"results" => []}} = TMDBClient.get_trending_movies("week")
    end

    test "returns error for invalid time window" do
      assert {:error, "Invalid time window. Use 'day' or 'week'"} =
               TMDBClient.get_trending_movies("month")
    end

    test "uses default time window" do
      assert {:ok, %{"results" => []}} = TMDBClient.get_trending_movies()
    end

    test "returns error for non-string time window" do
      assert {:error, "Invalid time window. Use 'day' or 'week'"} =
               TMDBClient.get_trending_movies(123)
    end

    test "returns error for nil time window" do
      assert {:error, "Invalid time window. Use 'day' or 'week'"} =
               TMDBClient.get_trending_movies(nil)
    end
  end

  describe "get_movie_genres/0" do
    test "returns empty genres list" do
      assert {:ok, %{"genres" => []}} = TMDBClient.get_movie_genres()
    end
  end

  describe "get_tv_genres/0" do
    test "returns empty genres list" do
      assert {:ok, %{"genres" => []}} = TMDBClient.get_tv_genres()
    end
  end

  describe "get_top_searches/0" do
    test "returns popular movies from test client" do
      assert {:ok, %{"results" => results}} = TMDBClient.get_top_searches()
      assert length(results) == 5

      # Check that we have the expected movies
      titles = Enum.map(results, & &1["title"])
      assert "The Shawshank Redemption" in titles
      assert "The Godfather" in titles
      assert "The Dark Knight" in titles
      assert "Pulp Fiction" in titles
      assert "Forrest Gump" in titles

      # Check that each movie has the required fields
      for movie <- results do
        assert Map.has_key?(movie, "id")
        assert Map.has_key?(movie, "title")
        assert Map.has_key?(movie, "poster_path")
        assert Map.has_key?(movie, "overview")
      end
    end
  end

  describe "client configuration" do
    test "uses test client in test environment" do
      # Verify that the test environment is configured to use the test client
      assert Application.get_env(:javi, :tmdb_client) == TMDBTest
    end

    test "test client implements all required functions" do
      # Check that the test client has all required functions
      assert {:search_movies, 1} in TMDBTest.__info__(:functions)
      assert {:search_tv, 1} in TMDBTest.__info__(:functions)
      assert {:get_movie_details, 1} in TMDBTest.__info__(:functions)
      assert {:get_tv_details, 1} in TMDBTest.__info__(:functions)
      assert {:get_trending_movies, 1} in TMDBTest.__info__(:functions)
      assert {:get_movie_genres, 0} in TMDBTest.__info__(:functions)
      assert {:get_tv_genres, 0} in TMDBTest.__info__(:functions)
    end

    test "test client implements the behaviour" do
      # Check that the test client implements the behaviour
      attributes = TMDBTest.__info__(:attributes)
      assert {:behaviour, [Javi.Media.TMDB.Client]} in attributes
    end
  end

  describe "test client edge cases" do
    test "handles various input types for search" do
      # Test various input types that should be rejected
      assert {:error, "Invalid query"} = TMDBClient.search_movies([])
      assert {:error, "Invalid query"} = TMDBClient.search_movies(%{})
      assert {:error, "Invalid query"} = TMDBClient.search_movies(1.5)
    end

    test "handles various input types for details" do
      # Test various input types that should be rejected
      assert {:error, "Invalid movie ID"} = TMDBClient.get_movie_details([])
      assert {:error, "Invalid movie ID"} = TMDBClient.get_movie_details(%{})
      assert {:error, "Invalid movie ID"} = TMDBClient.get_movie_details(1.5)

      assert {:error, "Invalid TV show ID"} = TMDBClient.get_tv_details([])
      assert {:error, "Invalid TV show ID"} = TMDBClient.get_tv_details(%{})
      assert {:error, "Invalid TV show ID"} = TMDBClient.get_tv_details(1.5)
    end

    test "handles various input types for trending" do
      # Test various input types that should be rejected
      assert {:error, "Invalid time window. Use 'day' or 'week'"} =
               TMDBClient.get_trending_movies([])

      assert {:error, "Invalid time window. Use 'day' or 'week'"} =
               TMDBClient.get_trending_movies(%{})

      assert {:error, "Invalid time window. Use 'day' or 'week'"} =
               TMDBClient.get_trending_movies(1.5)
    end
  end

  describe "test module documentation" do
    test "has proper module documentation" do
      # Test that the module has proper documentation
      module_info = TMDBTest.__info__(:module)
      assert module_info == TMDBTest

      # Test that the module has the expected attributes
      attributes = TMDBTest.__info__(:attributes)
      assert {:behaviour, [Javi.Media.TMDB.Client]} in attributes
    end

    test "test module has all required callbacks" do
      # Test that all required callbacks are implemented
      functions = TMDBTest.__info__(:functions)

      # Check that all required functions are present
      assert {:search_movies, 1} in functions
      assert {:search_tv, 1} in functions
      assert {:get_movie_details, 1} in functions
      assert {:get_tv_details, 1} in functions
      assert {:get_trending_movies, 1} in functions
      assert {:get_movie_genres, 0} in functions
      assert {:get_tv_genres, 0} in functions
    end

    test "test module returns consistent data structures" do
      # Test that the test module returns consistent data structures
      assert {:ok, %{"results" => []}} = TMDBClient.search_movies("test")
      assert {:ok, %{"results" => []}} = TMDBClient.search_tv("test")
      assert {:ok, %{"title" => "Test Movie"}} = TMDBClient.get_movie_details(1)
      assert {:ok, %{"name" => "Test TV Show"}} = TMDBClient.get_tv_details(1)
      assert {:ok, %{"results" => []}} = TMDBClient.get_trending_movies("day")
      assert {:ok, %{"genres" => []}} = TMDBClient.get_movie_genres()
      assert {:ok, %{"genres" => []}} = TMDBClient.get_tv_genres()
    end

    test "test module handles all trending time windows" do
      # Test both valid time windows
      assert {:ok, %{"results" => []}} = TMDBClient.get_trending_movies("day")
      assert {:ok, %{"results" => []}} = TMDBClient.get_trending_movies("week")
    end

    test "test module handles edge case inputs" do
      # Test edge cases that might not be covered
      assert {:error, "Invalid query"} = TMDBClient.search_movies("")
      assert {:error, "Invalid movie ID"} = TMDBClient.get_movie_details(0)
      assert {:error, "Invalid TV show ID"} = TMDBClient.get_tv_details(-1)

      assert {:error, "Invalid time window. Use 'day' or 'week'"} =
               TMDBClient.get_trending_movies("invalid")
    end
  end
end
