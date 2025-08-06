defmodule JaviWeb.Helpers.GenreHelper do
  @moduledoc """
  Helper functions for genre translations and formatting.
  """

  # TMDB Genre ID to Portuguese name mapping
  @genre_id_translations %{
    "28" => "Ação",
    "12" => "Aventura",
    "16" => "Animação",
    "35" => "Comédia",
    "80" => "Crime",
    "99" => "Documentário",
    "18" => "Drama",
    "10751" => "Família",
    "14" => "Fantasia",
    "36" => "História",
    "27" => "Terror",
    "10402" => "Música",
    "9648" => "Mistério",
    "10749" => "Romance",
    "878" => "Ficção Científica",
    "10770" => "Filme para TV",
    "53" => "Suspense",
    "37" => "Faroeste"
  }

  # Fallback English name to Portuguese mapping (for backward compatibility)
  @genre_translations %{
    "Action" => "Ação",
    "Adventure" => "Aventura",
    "Animation" => "Animação",
    "Comedy" => "Comédia",
    "Crime" => "Crime",
    "Documentary" => "Documentário",
    "Drama" => "Drama",
    "Family" => "Família",
    "Fantasy" => "Fantasia",
    "History" => "História",
    "Horror" => "Terror",
    "Music" => "Música",
    "Mystery" => "Mistério",
    "Romance" => "Romance",
    "Science Fiction" => "Ficção Científica",
    "TV Movie" => "Filme para TV",
    "Thriller" => "Suspense",
    "War" => "Guerra",
    "Western" => "Faroeste"
  }

  @doc """
  Translates a genre ID to Portuguese name.
  Returns the original ID if no translation is found.
  """
  def translate_genre_id(genre_id) when is_binary(genre_id) do
    @genre_id_translations[genre_id] || genre_id
  end

  @doc """
  Translates a list of genre IDs to Portuguese names.
  """
  def translate_genre_ids(genre_ids) when is_list(genre_ids) do
    Enum.map(genre_ids, &translate_genre_id/1)
  end

  @doc """
  Translates a genre name from English to Portuguese.
  Returns the original name if no translation is found.
  """
  def translate_genre(genre) when is_binary(genre) do
    @genre_translations[genre] || genre
  end

  @doc """
  Translates a list of genre names from English to Portuguese.
  """
  def translate_genres(genres) when is_list(genres) do
    Enum.map(genres, &translate_genre/1)
  end
end
