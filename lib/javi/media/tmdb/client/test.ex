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
    {:ok, %{"title" => "Test Movie"}}
  end

  def get_movie_details(_), do: {:error, "Invalid movie ID"}

  @impl Javi.Media.TMDB.Client
  def get_tv_details(tv_id) when is_integer(tv_id) and tv_id > 0 do
    {:ok, %{"name" => "Test TV Show"}}
  end

  def get_tv_details(_), do: {:error, "Invalid TV show ID"}

  @impl Javi.Media.TMDB.Client
  def get_trending_movies(time_window \\ "day")

  def get_trending_movies(time_window) when time_window in ["day", "week"] do
    {:ok, %{"results" => []}}
  end

  def get_trending_movies(_), do: {:error, "Invalid time window. Use 'day' or 'week'"}

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
end
