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
  @callback get_movie_genres() :: {:ok, map()} | {:error, String.t()}
  @callback get_tv_genres() :: {:ok, map()} | {:error, String.t()}
  @callback get_top_searches() :: {:ok, map()} | {:error, String.t()}

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

  def get_movie_genres() do
    get_client().get_movie_genres()
  end

  def get_tv_genres() do
    get_client().get_tv_genres()
  end

  def get_top_searches() do
    get_client().get_top_searches()
  end

  defp get_client do
    Application.get_env(:javi, :tmdb_client)
  end
end
