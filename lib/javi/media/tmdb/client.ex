defmodule Javi.Media.TMDB.Client do
  @moduledoc """
  Behaviour for TMDB client operations.
  This module defines the interface that all TMDB client implementations must follow.
  """

  @callback search_movies(String.t()) :: {:ok, map()} | {:error, String.t()}
  @callback search_tv(String.t()) :: {:ok, map()} | {:error, String.t()}
  @callback get_movie_details(integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_tv_details(integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_trending_movies(String.t()) :: {:ok, map()} | {:error, String.t()}
  @callback get_trending_tv(String.t()) :: {:ok, map()} | {:error, String.t()}
  @callback get_popular_movies() :: {:ok, map()} | {:error, String.t()}
  @callback get_top_rated_movies() :: {:ok, map()} | {:error, String.t()}
  @callback get_upcoming_movies() :: {:ok, map()} | {:error, String.t()}
  @callback get_movie_genres() :: {:ok, map()} | {:error, String.t()}
  @callback get_tv_genres() :: {:ok, map()} | {:error, String.t()}
  @callback get_top_searches() :: {:ok, map()} | {:error, String.t()}
  @callback get_recent_movies() :: {:ok, map()} | {:error, String.t()}
  @callback get_movies_by_genre(integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_movies_by_genre(integer(), integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_popular_movies_by_genre(integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_popular_movies_by_genre(integer(), integer()) ::
              {:ok, map()} | {:error, String.t()}
  @callback get_now_playing_movies() :: {:ok, map()} | {:error, String.t()}
  @callback get_popular_tv() :: {:ok, map()} | {:error, String.t()}
  @callback get_top_rated_tv() :: {:ok, map()} | {:error, String.t()}

  def search_movies(query) do
    get_client().search_movies(query)
  end

  def search_tv(query) do
    get_client().search_tv(query)
  end

  def get_movie_details(movie_id) do
    get_client().get_movie_details(movie_id)
  end

  def get_tv_details(tv_id) do
    get_client().get_tv_details(tv_id)
  end

  def get_trending_movies(time_window \\ "day") do
    get_client().get_trending_movies(time_window)
  end

  def get_trending_tv(time_window \\ "day") do
    get_client().get_trending_tv(time_window)
  end

  def get_popular_movies() do
    get_client().get_popular_movies()
  end

  def get_top_rated_movies() do
    get_client().get_top_rated_movies()
  end

  def get_upcoming_movies() do
    get_client().get_upcoming_movies()
  end

  def get_movie_genres() do
    get_client().get_movie_genres()
  end

  def get_tv_genres() do
    get_client().get_tv_genres()
  end

  def get_top_searches() do
    get_client().get_top_searches()
  end

  def get_recent_movies() do
    get_client().get_recent_movies()
  end

  def get_movies_by_genre(genre_id) do
    get_client().get_movies_by_genre(genre_id)
  end

  def get_movies_by_genre(genre_id, page) do
    get_client().get_movies_by_genre(genre_id, page)
  end

  def get_popular_movies_by_genre(genre_id) do
    get_client().get_popular_movies_by_genre(genre_id)
  end

  def get_popular_movies_by_genre(genre_id, page) do
    get_client().get_popular_movies_by_genre(genre_id, page)
  end

  def get_now_playing_movies() do
    get_client().get_now_playing_movies()
  end

  def get_popular_tv() do
    get_client().get_popular_tv()
  end

  def get_top_rated_tv() do
    get_client().get_top_rated_tv()
  end

  defp get_client do
    Application.get_env(:javi, :tmdb_client)
  end
end
