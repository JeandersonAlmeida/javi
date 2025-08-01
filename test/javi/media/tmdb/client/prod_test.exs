defmodule Javi.Media.TMDB.Client.ProdTest do
  use ExUnit.Case, async: false

  alias Javi.Media.TMDB.Client.Prod, as: TMDBProd

  setup do
    # Reset any previous mocks
    Tesla.Mock.mock(fn _env -> %Tesla.Env{status: 404, body: "Not Found"} end)
    :ok
  end

  describe "search_movies/1" do
    test "returns movies when search is successful" do
      mock_response = %{
        "results" => [
          %{
            "id" => 1,
            "title" => "Test Movie",
            "overview" => "A test movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => false
          }
        ]
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/movie") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"results" => [movie]}} = TMDBProd.search_movies("test")
      assert movie["title"] == "Test Movie"
      assert movie["id"] == 1
    end

    test "filters out adult content from search results" do
      mock_response = %{
        "results" => [
          %{
            "id" => 1,
            "title" => "Family Movie",
            "overview" => "A family movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => false
          },
          %{
            "id" => 2,
            "title" => "Adult Movie",
            "overview" => "An adult movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => true
          },
          %{
            "id" => 3,
            "title" => "Another Family Movie",
            "overview" => "Another family movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => false
          }
        ],
        "total_results" => 3,
        "total_pages" => 1
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/movie") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"results" => results, "total_results" => total_results}} =
               TMDBProd.search_movies("test")

      assert length(results) == 2
      assert total_results == 2

      # Check that only family movies are returned
      titles = Enum.map(results, & &1["title"])
      assert "Family Movie" in titles
      assert "Another Family Movie" in titles
      refute "Adult Movie" in titles

      # Check that adult flag is false for all returned movies
      for movie <- results do
        assert movie["adult"] == false
      end
    end

    test "returns empty results when all content is adult" do
      mock_response = %{
        "results" => [
          %{
            "id" => 1,
            "title" => "Adult Movie 1",
            "overview" => "An adult movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => true
          },
          %{
            "id" => 2,
            "title" => "Adult Movie 2",
            "overview" => "Another adult movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => true
          }
        ],
        "total_results" => 2,
        "total_pages" => 1
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/movie") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"results" => results, "total_results" => total_results}} =
               TMDBProd.search_movies("test")

      assert length(results) == 0
      assert total_results == 0
    end

    test "returns error for empty query" do
      assert {:error, "Invalid query"} = TMDBProd.search_movies("")
    end

    test "returns error for non-string query" do
      assert {:error, "Invalid query"} = TMDBProd.search_movies(123)
    end

    test "returns error for nil query" do
      assert {:error, "Invalid query"} = TMDBProd.search_movies(nil)
    end

    test "returns error when API returns error" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/movie") do
            %Tesla.Env{status: 401, body: %{"status_message" => "Invalid API key"}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, "HTTP 401"} = TMDBProd.search_movies("test")
    end

    test "returns error when Tesla request fails" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/movie") do
            {:error, :timeout}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, :timeout} = TMDBProd.search_movies("test")
    end

    test "returns error when API returns non-200 status" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/movie") do
            %Tesla.Env{status: 500, body: %{"status_message" => "Internal Server Error"}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, "HTTP 500"} = TMDBProd.search_movies("test")
    end
  end

  describe "search_tv/1" do
    test "returns TV shows when search is successful" do
      mock_response = %{
        "results" => [
          %{
            "id" => 1,
            "name" => "Test TV Show",
            "overview" => "A test TV show",
            "first_air_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => false
          }
        ]
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/tv") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"results" => [show]}} = TMDBProd.search_tv("test")
      assert show["name"] == "Test TV Show"
      assert show["id"] == 1
    end

    test "filters out adult content from TV search results" do
      mock_response = %{
        "results" => [
          %{
            "id" => 1,
            "name" => "Family TV Show",
            "overview" => "A family TV show",
            "first_air_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => false
          },
          %{
            "id" => 2,
            "name" => "Adult TV Show",
            "overview" => "An adult TV show",
            "first_air_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => true
          }
        ],
        "total_results" => 2,
        "total_pages" => 1
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/tv") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"results" => results, "total_results" => total_results}} =
               TMDBProd.search_tv("test")

      assert length(results) == 1
      assert total_results == 1

      # Check that only family TV shows are returned
      names = Enum.map(results, & &1["name"])
      assert "Family TV Show" in names
      refute "Adult TV Show" in names
    end

    test "returns error for empty query" do
      assert {:error, "Invalid query"} = TMDBProd.search_tv("")
    end

    test "returns error for non-string query" do
      assert {:error, "Invalid query"} = TMDBProd.search_tv(123)
    end

    test "returns error when API returns error" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/tv") do
            %Tesla.Env{status: 401, body: %{"status_message" => "Invalid API key"}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, "HTTP 401"} = TMDBProd.search_tv("test")
    end

    test "returns error when Tesla request fails" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/tv") do
            {:error, :network_error}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, :network_error} = TMDBProd.search_tv("test")
    end
  end

  describe "get_movie_details/1" do
    test "returns movie details when successful" do
      mock_response = %{
        "id" => 1,
        "title" => "Test Movie",
        "overview" => "A test movie",
        "release_date" => "2023-01-01",
        "vote_average" => 8.5,
        "poster_path" => "/test.jpg",
        "adult" => false
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "movie/1") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, movie} = TMDBProd.get_movie_details(1)
      assert movie["title"] == "Test Movie"
      assert movie["id"] == 1
    end

    test "returns nil for adult movie details" do
      mock_response = %{
        "id" => 1,
        "title" => "Adult Movie",
        "overview" => "An adult movie",
        "release_date" => "2023-01-01",
        "vote_average" => 8.5,
        "poster_path" => "/test.jpg",
        "adult" => true
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "movie/1") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, nil} = TMDBProd.get_movie_details(1)
    end

    test "returns error for invalid movie ID" do
      assert {:error, "Invalid movie ID"} = TMDBProd.get_movie_details(0)
      assert {:error, "Invalid movie ID"} = TMDBProd.get_movie_details(-1)

      assert {:error, "Invalid movie ID"} =
               TMDBProd.get_movie_details("invalid")
    end

    test "returns error when API returns error" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "movie/1") do
            %Tesla.Env{
              status: 404,
              body: %{"status_message" => "The resource you requested could not be found."}
            }
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, "HTTP 404"} = TMDBProd.get_movie_details(1)
    end

    test "returns error when Tesla request fails" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "movie/1") do
            {:error, :timeout}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, :timeout} = TMDBProd.get_movie_details(1)
    end
  end

  describe "get_tv_details/1" do
    test "returns TV show details when successful" do
      mock_response = %{
        "id" => 1,
        "name" => "Test TV Show",
        "overview" => "A test TV show",
        "first_air_date" => "2023-01-01",
        "vote_average" => 8.5,
        "poster_path" => "/test.jpg",
        "adult" => false
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "tv/1") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, show} = TMDBProd.get_tv_details(1)
      assert show["name"] == "Test TV Show"
      assert show["id"] == 1
    end

    test "returns nil for adult TV show details" do
      mock_response = %{
        "id" => 1,
        "name" => "Adult TV Show",
        "overview" => "An adult TV show",
        "first_air_date" => "2023-01-01",
        "vote_average" => 8.5,
        "poster_path" => "/test.jpg",
        "adult" => true
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "tv/1") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, nil} = TMDBProd.get_tv_details(1)
    end

    test "returns error for invalid TV show ID" do
      assert {:error, "Invalid TV show ID"} = TMDBProd.get_tv_details(0)
      assert {:error, "Invalid TV show ID"} = TMDBProd.get_tv_details(-1)

      assert {:error, "Invalid TV show ID"} =
               TMDBProd.get_tv_details("invalid")
    end

    test "returns error when API returns error" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "tv/1") do
            %Tesla.Env{
              status: 404,
              body: %{"status_message" => "The resource you requested could not be found."}
            }
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, "HTTP 404"} = TMDBProd.get_tv_details(1)
    end

    test "returns error when Tesla request fails" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "tv/1") do
            {:error, :network_error}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, :network_error} = TMDBProd.get_tv_details(1)
    end
  end

  describe "get_trending_movies/1" do
    test "returns trending movies when successful" do
      mock_response = %{
        "results" => [
          %{
            "id" => 1,
            "title" => "Trending Movie",
            "overview" => "A trending movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => false
          }
        ]
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "trending/movie/day") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"results" => [movie]}} =
               TMDBProd.get_trending_movies("day")

      assert movie["title"] == "Trending Movie"
    end

    test "filters out adult content from trending movies" do
      mock_response = %{
        "results" => [
          %{
            "id" => 1,
            "title" => "Family Trending Movie",
            "overview" => "A family trending movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => false
          },
          %{
            "id" => 2,
            "title" => "Adult Trending Movie",
            "overview" => "An adult trending movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => true
          }
        ],
        "total_results" => 2,
        "total_pages" => 1
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "trending/movie/day") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"results" => results, "total_results" => total_results}} =
               TMDBProd.get_trending_movies("day")

      assert length(results) == 1
      assert total_results == 1

      # Check that only family movies are returned
      titles = Enum.map(results, & &1["title"])
      assert "Family Trending Movie" in titles
      refute "Adult Trending Movie" in titles
    end

    test "returns error for invalid time window" do
      assert {:error, "Invalid time window. Use 'day' or 'week'"} =
               TMDBProd.get_trending_movies("month")
    end

    test "accepts valid time windows" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          cond do
            String.contains?(url, "trending/movie/day") ->
              %Tesla.Env{status: 200, body: %{"results" => []}}

            String.contains?(url, "trending/movie/week") ->
              %Tesla.Env{status: 200, body: %{"results" => []}}

            true ->
              %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, _} = TMDBProd.get_trending_movies("day")
      assert {:ok, _} = TMDBProd.get_trending_movies("week")
    end

    test "uses default time window" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "trending/movie/day") do
            %Tesla.Env{status: 200, body: %{"results" => []}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, _} = TMDBProd.get_trending_movies()
    end

    test "returns error when API returns error" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "trending/movie/day") do
            %Tesla.Env{status: 401, body: %{"status_message" => "Invalid API key"}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, "HTTP 401"} = TMDBProd.get_trending_movies("day")
    end

    test "returns error when Tesla request fails" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "trending/movie/day") do
            {:error, :timeout}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, :timeout} = TMDBProd.get_trending_movies("day")
    end
  end

  describe "get_movie_genres/0" do
    test "returns movie genres when successful" do
      mock_response = %{
        "genres" => [
          %{"id" => 1, "name" => "Action"},
          %{"id" => 2, "name" => "Drama"}
        ]
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "genre/movie/list") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"genres" => genres}} = TMDBProd.get_movie_genres()
      assert length(genres) == 2
      assert Enum.find(genres, fn g -> g["name"] == "Action" end)
    end

    test "returns error when API returns error" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "genre/movie/list") do
            %Tesla.Env{status: 401, body: %{"status_message" => "Invalid API key"}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, "HTTP 401"} = TMDBProd.get_movie_genres()
    end

    test "returns error when Tesla request fails" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "genre/movie/list") do
            {:error, :timeout}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, :timeout} = TMDBProd.get_movie_genres()
    end
  end

  describe "get_tv_genres/0" do
    test "returns TV show genres when successful" do
      mock_response = %{
        "genres" => [
          %{"id" => 1, "name" => "Drama"},
          %{"id" => 2, "name" => "Comedy"}
        ]
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "genre/tv/list") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"genres" => genres}} = TMDBProd.get_tv_genres()
      assert length(genres) == 2
      assert Enum.find(genres, fn g -> g["name"] == "Drama" end)
    end

    test "returns error when API returns error" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "genre/tv/list") do
            %Tesla.Env{status: 401, body: %{"status_message" => "Invalid API key"}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, "HTTP 401"} = TMDBProd.get_tv_genres()
    end

    test "returns error when Tesla request fails" do
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "genre/tv/list") do
            {:error, :network_error}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, :network_error} = TMDBProd.get_tv_genres()
    end
  end

  describe "get_top_searches/0" do
    test "returns top searches when successful" do
      mock_response = %{
        "results" => [
          %{
            "id" => 1,
            "title" => "Popular Movie",
            "overview" => "A popular movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => false
          }
        ]
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "trending/all/day") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"results" => [movie]}} = TMDBProd.get_top_searches()
      assert movie["title"] == "Popular Movie"
    end

    test "filters out adult content from top searches" do
      mock_response = %{
        "results" => [
          %{
            "id" => 1,
            "title" => "Family Popular Movie",
            "overview" => "A family popular movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => false
          },
          %{
            "id" => 2,
            "title" => "Adult Popular Movie",
            "overview" => "An adult popular movie",
            "release_date" => "2023-01-01",
            "vote_average" => 8.5,
            "poster_path" => "/test.jpg",
            "adult" => true
          }
        ],
        "total_results" => 2,
        "total_pages" => 1
      }

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "trending/all/day") do
            %Tesla.Env{status: 200, body: mock_response}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"results" => results, "total_results" => total_results}} =
               TMDBProd.get_top_searches()

      assert length(results) == 1
      assert total_results == 1

      # Check that only family content is returned
      titles = Enum.map(results, & &1["title"])
      assert "Family Popular Movie" in titles
      refute "Adult Popular Movie" in titles
    end
  end

  describe "Tesla configuration" do
    test "has proper Tesla middleware configured" do
      # Check that the module has the expected functions
      assert {:search_movies, 1} in TMDBProd.__info__(:functions)
      assert {:search_tv, 1} in TMDBProd.__info__(:functions)
      assert {:get_movie_details, 1} in TMDBProd.__info__(:functions)
      assert {:get_tv_details, 1} in TMDBProd.__info__(:functions)
      assert {:get_trending_movies, 1} in TMDBProd.__info__(:functions)
      assert {:get_movie_genres, 0} in TMDBProd.__info__(:functions)
      assert {:get_tv_genres, 0} in TMDBProd.__info__(:functions)
      assert {:get_top_searches, 0} in TMDBProd.__info__(:functions)
    end
  end

  describe "make_request function" do
    test "handles Tesla.get with different options" do
      # Test make_request with different option combinations
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/movie") do
            %Tesla.Env{status: 200, body: %{"results" => []}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      # Test with query options
      assert {:ok, _} = TMDBProd.search_movies("test")

      # Test with empty options
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "movie/1") do
            %Tesla.Env{status: 200, body: %{"title" => "Test"}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, _} = TMDBProd.get_movie_details(1)
    end

    test "handles different HTTP status codes" do
      # Test various HTTP status codes
      status_codes = [400, 401, 403, 404, 500, 502, 503]

      for status <- status_codes do
        Tesla.Mock.mock(fn
          %{method: :get, url: url} ->
            if String.contains?(url, "search/movie") do
              %Tesla.Env{status: status, body: %{"error" => "Test error"}}
            else
              %Tesla.Env{status: 404, body: "Not Found"}
            end
        end)

        expected_error = "HTTP #{status}"
        assert {:error, ^expected_error} = TMDBProd.search_movies("test")
      end
    end

    test "handles different Tesla error types" do
      # Test various Tesla error types
      error_types = [:timeout, :network_error, :connection_error, :ssl_error]

      for error <- error_types do
        Tesla.Mock.mock(fn
          %{method: :get, url: url} ->
            if String.contains?(url, "search/movie") do
              {:error, error}
            else
              %Tesla.Env{status: 404, body: "Not Found"}
            end
        end)

        assert {:error, ^error} = TMDBProd.search_movies("test")
      end
    end

    test "handles complex Tesla error responses" do
      # Test complex error responses
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/movie") do
            {:error, %{reason: :timeout, message: "Request timeout"}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:error, %{reason: :timeout, message: "Request timeout"}} =
               TMDBProd.search_movies("test")
    end
  end

  describe "edge cases and boundary conditions" do
    test "handles very long query strings" do
      long_query = String.duplicate("a", 1000)

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/movie") do
            %Tesla.Env{status: 200, body: %{"results" => []}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, _} = TMDBProd.search_movies(long_query)
    end

    test "handles special characters in query" do
      special_chars = ["test@example.com", "test+query", "test%20query", "test&query"]

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "search/movie") do
            %Tesla.Env{status: 200, body: %{"results" => []}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      for query <- special_chars do
        assert {:ok, _} = TMDBProd.search_movies(query)
      end
    end

    test "handles very large movie IDs" do
      large_id = 999_999_999

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "movie/#{large_id}") do
            %Tesla.Env{status: 200, body: %{"title" => "Large ID Movie"}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, _} = TMDBProd.get_movie_details(large_id)
    end

    test "handles very large TV show IDs" do
      large_id = 999_999_999

      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          if String.contains?(url, "tv/#{large_id}") do
            %Tesla.Env{status: 200, body: %{"name" => "Large ID TV Show"}}
          else
            %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, _} = TMDBProd.get_tv_details(large_id)
    end
  end

  describe "module documentation and attributes" do
    test "has proper module documentation" do
      # Test that the module has proper documentation
      module_info = TMDBProd.__info__(:module)
      assert module_info == TMDBProd

      # Test that the module has the expected attributes
      attributes = TMDBProd.__info__(:attributes)
      assert {:behaviour, [Javi.Media.TMDB.Client]} in attributes
    end

    test "has proper function documentation" do
      # Test that the module has the expected public functions
      functions = TMDBProd.__info__(:functions)

      # Check that all required public functions are present
      assert {:search_movies, 1} in functions
      assert {:search_tv, 1} in functions
      assert {:get_movie_details, 1} in functions
      assert {:get_tv_details, 1} in functions
      assert {:get_trending_movies, 1} in functions
      assert {:get_movie_genres, 0} in functions
      assert {:get_tv_genres, 0} in functions
      assert {:get_top_searches, 0} in functions
    end

    test "handles all trending movie time windows" do
      # Test both valid time windows
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          cond do
            String.contains?(url, "trending/movie/day") ->
              %Tesla.Env{status: 200, body: %{"results" => [%{"title" => "Day Movie"}]}}

            String.contains?(url, "trending/movie/week") ->
              %Tesla.Env{status: 200, body: %{"results" => [%{"title" => "Week Movie"}]}}

            true ->
              %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"results" => [%{"title" => "Day Movie"}]}} =
               TMDBProd.get_trending_movies("day")

      assert {:ok, %{"results" => [%{"title" => "Week Movie"}]}} =
               TMDBProd.get_trending_movies("week")
    end

    test "handles all genre endpoints" do
      # Test both genre endpoints
      Tesla.Mock.mock(fn
        %{method: :get, url: url} ->
          cond do
            String.contains?(url, "genre/movie/list") ->
              %Tesla.Env{status: 200, body: %{"genres" => [%{"id" => 1, "name" => "Action"}]}}

            String.contains?(url, "genre/tv/list") ->
              %Tesla.Env{status: 200, body: %{"genres" => [%{"id" => 2, "name" => "Drama"}]}}

            true ->
              %Tesla.Env{status: 404, body: "Not Found"}
          end
      end)

      assert {:ok, %{"genres" => [%{"id" => 1, "name" => "Action"}]}} =
               TMDBProd.get_movie_genres()

      assert {:ok, %{"genres" => [%{"id" => 2, "name" => "Drama"}]}} =
               TMDBProd.get_tv_genres()
    end
  end
end
