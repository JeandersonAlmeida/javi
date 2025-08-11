defmodule Javi.Media.TMDB.Client.Test do
  @moduledoc """
  Test implementation of TMDB client for mocking in tests.
  """

  @behaviour Javi.Media.TMDB.Client

  @impl Javi.Media.TMDB.Client
  def search_movies(query) when is_binary(query) and query != "" do
    {:ok, %{"results" => []}}
  end

  def search_movies(_), do: {:error, "Invalid query"}

  @impl Javi.Media.TMDB.Client
  def search_tv(query) when is_binary(query) and query != "" do
    {:ok, %{"results" => []}}
  end

  def search_tv(_), do: {:error, "Invalid query"}

  @impl Javi.Media.TMDB.Client
  def get_movie_details(movie_id) when is_integer(movie_id) and movie_id > 0 do
    # Only return data for specific test IDs, fail for others
    case movie_id do
      id when id in [123, 12345, 1696] ->
        {:ok,
         %{
           "id" => movie_id,
           "title" => "Test Movie",
           "original_title" => "Test Movie",
           "overview" => "A test movie",
           "release_date" => "2023-01-01",
           "vote_average" => 7.5,
           "vote_count" => 1000,
           "popularity" => 100.0,
           "poster_path" => "/test.jpg",
           "backdrop_path" => "/backdrop.jpg",
           "adult" => false,
           "genres" => [%{"id" => 28, "name" => "Action"}, %{"id" => 12, "name" => "Adventure"}],
           "runtime" => 120
         }}

      _ ->
        {:error, "Movie not found"}
    end
  end

  def get_movie_details(_), do: {:error, "Invalid movie ID"}

  @impl Javi.Media.TMDB.Client
  def get_tv_details(tv_id) when is_integer(tv_id) and tv_id > 0 do
    # Only return data for specific test IDs, fail for others
    case tv_id do
      id when id in [456, 12345] ->
        {:ok,
         %{
           "id" => tv_id,
           "name" => "Test TV Show",
           "original_name" => "Test TV Show",
           "overview" => "A test TV show",
           "first_air_date" => "2023-01-01",
           "vote_average" => 8.5,
           "vote_count" => 1000,
           "popularity" => 100.0,
           "poster_path" => "/test.jpg",
           "backdrop_path" => "/backdrop.jpg",
           "adult" => false,
           "genres" => [
             %{"id" => 10759, "name" => "Action & Adventure"},
             %{"id" => 35, "name" => "Comedy"}
           ],
           "episode_run_time" => [45],
           "number_of_seasons" => 1,
           "number_of_episodes" => 10
         }}

      _ ->
        {:error, "TV show not found"}
    end
  end

  def get_tv_details(_), do: {:error, "Invalid TV show ID"}

  @impl Javi.Media.TMDB.Client
  def get_trending_movies(time_window \\ "day")

  def get_trending_movies(time_window) when time_window in ["day", "week"] do
    {:ok, %{"results" => []}}
  end

  def get_trending_movies(_), do: {:error, "Invalid time window. Use 'day' or 'week'"}

  @impl Javi.Media.TMDB.Client
  def get_trending_tv(_time_window \\ "day") do
    {:ok,
     %{
       "results" => [
         %{
           "id" => 101,
           "name" => "Test TV Show 1",
           "overview" => "A test TV show",
           "poster_path" => "/tv1.jpg",
           "first_air_date" => "2023-01-01",
           "vote_average" => 8.2,
           "vote_count" => 500,
           "popularity" => 85.0,
           "adult" => false,
           "genre_ids" => [18, 80],
           "media_type" => "tv"
         },
         %{
           "id" => 102,
           "name" => "Test TV Show 2",
           "overview" => "Another test TV show",
           "poster_path" => "/tv2.jpg",
           "first_air_date" => "2023-02-01",
           "vote_average" => 7.5,
           "vote_count" => 400,
           "popularity" => 75.0,
           "adult" => false,
           "genre_ids" => [16, 35],
           "media_type" => "tv"
         }
       ]
     }}
  end

  @impl Javi.Media.TMDB.Client
  def get_popular_movies do
    {:ok,
     %{
       "results" => [
         %{
           "id" => 101,
           "title" => "Popular Movie 1",
           "poster_path" => "/popular1.jpg",
           "overview" => "A popular movie description"
         },
         %{
           "id" => 102,
           "title" => "Popular Movie 2",
           "poster_path" => "/popular2.jpg",
           "overview" => "Another popular movie description"
         }
       ]
     }}
  end

  @impl Javi.Media.TMDB.Client
  def get_top_rated_movies do
    {:ok,
     %{
       "results" => [
         %{
           "id" => 201,
           "title" => "Top Rated Movie 1",
           "poster_path" => "/toprated1.jpg",
           "overview" => "A top rated movie description"
         },
         %{
           "id" => 202,
           "title" => "Top Rated Movie 2",
           "poster_path" => "/toprated2.jpg",
           "overview" => "Another top rated movie description"
         }
       ]
     }}
  end

  @impl Javi.Media.TMDB.Client
  def get_upcoming_movies do
    {:ok,
     %{
       "results" => [
         %{
           "id" => 301,
           "title" => "Upcoming Movie 1",
           "poster_path" => "/upcoming1.jpg",
           "overview" => "An upcoming movie description"
         },
         %{
           "id" => 302,
           "title" => "Upcoming Movie 2",
           "poster_path" => "/upcoming2.jpg",
           "overview" => "Another upcoming movie description"
         }
       ]
     }}
  end

  @impl Javi.Media.TMDB.Client
  def get_movie_genres do
    {:ok, %{"genres" => []}}
  end

  @impl Javi.Media.TMDB.Client
  def get_tv_genres do
    {:ok, %{"genres" => []}}
  end

  @impl Javi.Media.TMDB.Client
  def get_top_searches do
    {:ok,
     %{
       "results" => [
         %{
           "id" => 1,
           "title" => "The Shawshank Redemption",
           "poster_path" => "/9O7gLzmreU0nGkIB6K3BsJbzvNx.jpg",
           "overview" => "Framed in the 1940s for the double murder of his wife and her lover..."
         },
         %{
           "id" => 2,
           "title" => "The Godfather",
           "poster_path" => "/3bhkrj58Vtu7enYsRolD1fZdja1.jpg",
           "overview" =>
             "Spanning the years 1945 to 1955, a chronicle of the fictional Italian-American Corleone crime family..."
         },
         %{
           "id" => 3,
           "title" => "The Dark Knight",
           "poster_path" => "/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
           "overview" =>
             "When the menace known as the Joker wreaks havoc and chaos on the people of Gotham..."
         },
         %{
           "id" => 4,
           "title" => "Pulp Fiction",
           "poster_path" => "/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg",
           "overview" =>
             "A burger-loving hit man, his philosophical partner, a drug-addled gangster's moll..."
         },
         %{
           "id" => 5,
           "title" => "Forrest Gump",
           "poster_path" => "/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg",
           "overview" =>
             "A man with a low IQ has accomplished great things in his life and been present during significant historic events..."
         }
       ]
     }}
  end

  @impl Javi.Media.TMDB.Client
  def get_recent_movies do
    {:ok,
     %{
       "results" => [
         %{
           "id" => 1,
           "title" => "Recent Movie 1",
           "poster_path" => "/recent1.jpg",
           "release_date" => "2024-01-15"
         },
         %{
           "id" => 2,
           "title" => "Recent Movie 2",
           "poster_path" => "/recent2.jpg",
           "release_date" => "2024-01-20"
         }
       ]
     }}
  end

  @impl Javi.Media.TMDB.Client
  def get_movies_by_genre(genre_id) when is_integer(genre_id) and genre_id > 0 do
    {:ok,
     %{
       "results" => [
         %{
           "id" => genre_id * 10 + 1,
           "title" => "Genre Movie 1",
           "poster_path" => "/genre1.jpg",
           "overview" => "A movie from genre #{genre_id}"
         },
         %{
           "id" => genre_id * 10 + 2,
           "title" => "Genre Movie 2",
           "poster_path" => "/genre2.jpg",
           "overview" => "Another movie from genre #{genre_id}"
         }
       ]
     }}
  end

  def get_movies_by_genre(_), do: {:error, "Invalid genre ID"}

  @impl Javi.Media.TMDB.Client
  def get_movies_by_genre(genre_id, page)
      when is_integer(genre_id) and genre_id > 0 and is_integer(page) and page > 0 do
    # Mock response for testing
    {:ok,
     %{
       "page" => page,
       "results" => [
         %{
           "id" => 2000 + page,
           "title" => "Test Movie by Genre #{page}",
           "overview" => "Test overview for movie by genre #{page}",
           "poster_path" => "/test-poster.jpg",
           "vote_average" => 7.0,
           "vote_count" => 80,
           "release_date" => "2024-01-01",
           "media_type" => "movie"
         }
       ],
       "total_pages" => 5,
       "total_results" => 100
     }}
  end

  def get_movies_by_genre(_, _), do: {:error, "Invalid genre ID or page"}

  @impl Javi.Media.TMDB.Client
  def get_popular_movies_by_genre(genre_id) when is_integer(genre_id) and genre_id > 0 do
    {:ok,
     %{
       "results" => [
         %{
           "id" => genre_id * 100 + 1,
           "title" => "Popular Genre Movie 1",
           "poster_path" => "/popular_genre1.jpg",
           "overview" => "A popular movie from genre #{genre_id}",
           "vote_average" => 8.5
         },
         %{
           "id" => genre_id * 100 + 2,
           "title" => "Popular Genre Movie 2",
           "poster_path" => "/popular_genre2.jpg",
           "overview" => "Another popular movie from genre #{genre_id}",
           "vote_average" => 7.8
         }
       ]
     }}
  end

  def get_popular_movies_by_genre(_), do: {:error, "Invalid genre ID"}

  @impl Javi.Media.TMDB.Client
  def get_popular_movies_by_genre(genre_id, page)
      when is_integer(genre_id) and genre_id > 0 and is_integer(page) and page > 0 do
    # Mock response for testing
    {:ok,
     %{
       "page" => page,
       "results" => [
         %{
           "id" => 1000 + page,
           "title" => "Test Movie #{page}",
           "overview" => "Test overview for movie #{page}",
           "poster_path" => "/test-poster.jpg",
           "vote_average" => 7.5,
           "vote_count" => 100,
           "release_date" => "2024-01-01",
           "media_type" => "movie"
         }
       ],
       "total_pages" => 5,
       "total_results" => 100
     }}
  end

  def get_popular_movies_by_genre(_, _), do: {:error, "Invalid genre ID or page"}

  @impl Javi.Media.TMDB.Client
  def get_now_playing_movies() do
    {:ok,
     %{
       "results" => [
         %{
           "id" => 1001,
           "title" => "Now Playing Movie 1",
           "overview" => "Test overview for now playing movie 1",
           "poster_path" => "/test-poster.jpg",
           "vote_average" => 7.8,
           "vote_count" => 150,
           "release_date" => "2024-01-15",
           "media_type" => "movie"
         }
       ]
     }}
  end

  @impl Javi.Media.TMDB.Client
  def get_popular_tv() do
    {:ok,
     %{
       "results" => [
         %{
           "id" => 2001,
           "name" => "Popular TV Show 1",
           "overview" => "Test overview for popular TV show 1",
           "poster_path" => "/test-poster.jpg",
           "vote_average" => 8.2,
           "vote_count" => 200,
           "first_air_date" => "2024-01-10",
           "media_type" => "tv"
         }
       ]
     }}
  end

  @impl Javi.Media.TMDB.Client
  def get_top_rated_tv() do
    {:ok,
     %{
       "results" => [
         %{
           "id" => 2002,
           "name" => "Top Rated TV Show 1",
           "overview" => "Test overview for top rated TV show 1",
           "poster_path" => "/test-poster.jpg",
           "vote_average" => 9.1,
           "vote_count" => 300,
           "first_air_date" => "2024-01-05",
           "media_type" => "tv"
         }
       ]
     }}
  end
end
