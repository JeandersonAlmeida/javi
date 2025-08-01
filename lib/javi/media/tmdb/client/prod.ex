defmodule Javi.Media.TMDB.Client.Prod do
  @moduledoc """
  Production implementation of TMDB client using Tesla for HTTP requests.
  """

  use Tesla
  @behaviour Javi.Media.TMDB.Client

  @base_url "https://api.themoviedb.org/3"

  plug Tesla.Middleware.BaseUrl, @base_url
  plug Tesla.Middleware.JSON

  @impl Javi.Media.TMDB.Client
  def search_movies(query) when is_binary(query) and query != "" do
    case get("/search/movie", query: [query: query, api_key: get_api_key(), language: "pt-BR"]) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, filter_movies_only(filter_adult_content(body))}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def search_movies(_), do: {:error, "Invalid query"}

  @impl Javi.Media.TMDB.Client
  def search_tv(query) when is_binary(query) and query != "" do
    case get("/search/tv", query: [query: query, api_key: get_api_key(), language: "pt-BR"]) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, filter_tv_only(filter_adult_content(body))}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def search_tv(_), do: {:error, "Invalid query"}

  @impl Javi.Media.TMDB.Client
  def get_movie_details(movie_id) when is_integer(movie_id) and movie_id > 0 do
    case get("/movie/#{movie_id}", query: [api_key: get_api_key(), language: "pt-BR"]) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, filter_adult_content(body)}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_movie_details(_), do: {:error, "Invalid movie ID"}

  @impl Javi.Media.TMDB.Client
  def get_tv_details(tv_id) when is_integer(tv_id) and tv_id > 0 do
    case get("/tv/#{tv_id}", query: [api_key: get_api_key(), language: "pt-BR"]) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, filter_adult_content(body)}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_tv_details(_), do: {:error, "Invalid TV show ID"}

  @impl Javi.Media.TMDB.Client
  def get_trending_movies(time_window \\ "day")

  def get_trending_movies(time_window) when time_window in ["day", "week"] do
    case get("/trending/movie/#{time_window}", query: [api_key: get_api_key(), language: "pt-BR"]) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, filter_adult_content(body)}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_trending_movies(_), do: {:error, "Invalid time window. Use 'day' or 'week'"}

  @impl Javi.Media.TMDB.Client
  def get_movie_genres do
    case get("/genre/movie/list", query: [api_key: get_api_key(), language: "pt-BR"]) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl Javi.Media.TMDB.Client
  def get_tv_genres do
    case get("/genre/tv/list", query: [api_key: get_api_key(), language: "pt-BR"]) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl Javi.Media.TMDB.Client
  def get_top_searches do
    case get("/trending/all/day", query: [api_key: get_api_key(), language: "pt-BR"]) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, filter_adult_content(body)}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions

  # Filters out adult content from API responses
  defp filter_adult_content(%{"results" => results} = response) when is_list(results) do
    filtered_results =
      Enum.reject(results, fn item ->
        Map.get(item, "adult", false) == true
      end)

    # Update the total results count
    total_results = length(filtered_results)
    total_pages = calculate_total_pages(total_results, Map.get(response, "total_pages", 1))

    response
    |> Map.put("results", filtered_results)
    |> Map.put("total_results", total_results)
    |> Map.put("total_pages", total_pages)
  end

  defp filter_adult_content(%{"adult" => true} = _item) do
    # If a single item is adult content, return nil or empty result
    nil
  end

  defp filter_adult_content(response) when is_map(response) do
    # For single item responses, check if it's adult content
    case Map.get(response, "adult", false) do
      true -> nil
      false -> response
    end
  end

  defp filter_adult_content(response), do: response

  # Filters to ensure only movies are returned (has title field, not name field)
  defp filter_movies_only(%{"results" => results} = response) when is_list(results) do
    filtered_results =
      Enum.filter(results, fn item ->
        # Movies have "title" field, TV shows have "name" field
        Map.has_key?(item, "title") and not Map.has_key?(item, "name")
      end)

    # Update the total results count
    total_results = length(filtered_results)
    total_pages = calculate_total_pages(total_results, Map.get(response, "total_pages", 1))

    response
    |> Map.put("results", filtered_results)
    |> Map.put("total_results", total_results)
    |> Map.put("total_pages", total_pages)
  end

  defp filter_movies_only(response), do: response

  # Filters to ensure only TV shows are returned (has name field, not title field)
  defp filter_tv_only(%{"results" => results} = response) when is_list(results) do
    filtered_results =
      Enum.filter(results, fn item ->
        # TV shows have "name" field, movies have "title" field
        Map.has_key?(item, "name") and not Map.has_key?(item, "title")
      end)

    # Update the total results count
    total_results = length(filtered_results)
    total_pages = calculate_total_pages(total_results, Map.get(response, "total_pages", 1))

    response
    |> Map.put("results", filtered_results)
    |> Map.put("total_results", total_results)
    |> Map.put("total_pages", total_pages)
  end

  defp filter_tv_only(response), do: response

  # Calculate total pages based on filtered results
  defp calculate_total_pages(total_results, _original_pages) when total_results <= 0 do
    0
  end

  defp calculate_total_pages(total_results, _original_pages) do
    # Assuming 20 results per page (TMDB default)
    ceil(total_results / 20)
  end

  # Gets the TMDB API key from application configuration.
  # Falls back to environment variable if not configured.
  defp get_api_key do
    case Application.get_env(:javi, :tmdb_api_key) do
      nil ->
        raise "TMDB API key not configured. Please set :tmdb_api_key in your application config."

      key when is_binary(key) ->
        key

      _ ->
        raise "Invalid TMDB API key configuration. Expected a string value."
    end
  end
end
