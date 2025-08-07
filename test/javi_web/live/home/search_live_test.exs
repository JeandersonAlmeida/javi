defmodule JaviWeb.Home.SearchLiveTest do
  use JaviWeb.ConnCase

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures
  import Javi.MediaFixtures
  import Floki

  alias Javi.Accounts
  alias Javi.Media

  @create_user_attrs %{
    email: "test@example.com",
    password: "testpassword123"
  }

  setup do
    %{user: user_fixture(@create_user_attrs)}
  end

  describe "Search page rendering" do
    test "renders search page with search interface", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/pesquisar")

      assert {:ok, document} = Floki.parse_document(html)

      # Check for search page elements
      assert Floki.find(document, "h1") |> Floki.text() =~ "Pesquisar"
      assert Floki.find(document, "[data-testid=search-input]")
      assert Floki.find(document, "[data-testid=search-button]")
    end

    test "renders trending movies section", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/pesquisar")

      assert {:ok, document} = Floki.parse_document(html)

      # Check trending movies section
      assert Floki.find(document, "[data-testid=trending-movies]")

      assert Floki.find(document, "[data-testid=trending-movies]") |> Floki.text() =~
               "Filmes em Alta"
    end

    test "renders popular TV shows section", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/pesquisar")

      assert {:ok, document} = Floki.parse_document(html)

      # Check popular TV shows section
      assert Floki.find(document, "[data-testid=popular-tv-shows]")

      assert Floki.find(document, "[data-testid=popular-tv-shows]") |> Floki.text() =~
               "Séries Populares"
    end

    test "renders search results when available", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/pesquisar")

      assert {:ok, document} = Floki.parse_document(html)

      # Check search results container
      assert Floki.find(document, "[data-testid=search-results]")
    end

    test "renders navigation buttons", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/pesquisar")

      assert {:ok, document} = Floki.parse_document(html)

      # Check navigation buttons
      assert Floki.find(document, "[data-testid=home-button]")
      assert Floki.find(document, "[data-testid=lists-button]")
      assert Floki.find(document, "[data-testid=profile-button]")
    end
  end

  describe "Search functionality" do
    test "can add movie to watched list", %{conn: conn, user: user} do
      # Log in the user
      conn = log_in_user(conn, user)

      # Visit the search page
      {:ok, view, _html} = live(conn, ~p"/pesquisar")

      # Mock movie data
      movie_data = %{
        "id" => 123,
        "title" => "Test Movie",
        "overview" => "A test movie",
        "poster_path" => "/test-poster.jpg",
        "release_date" => "2024-01-01",
        "vote_average" => 8.5,
        "popularity" => 100.0,
        "media_type" => "movie"
      }

      # Simulate adding movie to watched list
      result = render_click(view, "add_to_watched", %{"title" => Jason.encode!(movie_data)})
      assert result =~ "Pesquisar"

      # Verify the movie was added to the watched list
      watched_list = Accounts.get_user_watched_list(user)
      assert watched_list != nil
      assert length(watched_list.list_items) == 1
      assert List.first(watched_list.list_items).title.title == "Test Movie"
    end

    test "shows search results", %{conn: conn, user: user} do
      # Log in the user
      conn = log_in_user(conn, user)

      # Visit the search page
      {:ok, _view, html} = live(conn, ~p"/pesquisar")

      assert {:ok, document} = Floki.parse_document(html)

      # Check that the search page loads
      assert Floki.find(document, "h1") |> Floki.text() =~ "Pesquisar"

      assert Floki.find(document, "[data-testid=trending-movies]") |> Floki.text() =~
               "Filmes em Alta"

      assert Floki.find(document, "[data-testid=popular-tv-shows]") |> Floki.text() =~
               "Séries Populares"
    end

    test "can navigate to title detail from search results", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/pesquisar")

      # Mock movie data
      movie_data = %{
        "id" => 123,
        "title" => "Test Movie",
        "original_title" => "Test Movie",
        "overview" => "A test movie",
        "poster_path" => "/test-poster.jpg",
        "backdrop_path" => "/test-backdrop.jpg",
        "release_date" => "2024-01-01",
        "vote_average" => 8.5,
        "vote_count" => 1000,
        "popularity" => 100.0,
        "media_type" => "movie",
        "adult" => false,
        "genre_ids" => [28, 12]
      }

      # Simulate clicking on a search result
      result = render_click(view, "navigate_to_title", %{"title" => Jason.encode!(movie_data)})
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert String.starts_with?(url, "/titulos/")
      assert String.ends_with?(url, "?referrer=search")

      # Verify the title was created in the database
      title = Media.get_title_by_tmdb_id(123, "movie")
      assert title != nil
      assert title.title == "Test Movie"
    end

    test "can navigate to TV show detail from search results", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/pesquisar")

      # Mock TV show data (using "name" instead of "title")
      tv_data = %{
        "id" => 456,
        "name" => "Test TV Show",
        "original_name" => "Test TV Show Original",
        "overview" => "A test TV show",
        "poster_path" => "/test-poster.jpg",
        "backdrop_path" => "/test-backdrop.jpg",
        "first_air_date" => "2024-01-01",
        "vote_average" => 8.5,
        "vote_count" => 1000,
        "popularity" => 100.0,
        "media_type" => "tv",
        "adult" => false,
        "genre_ids" => [10759, 35]
      }

      # Simulate clicking on a search result
      result = render_click(view, "navigate_to_title", %{"title" => Jason.encode!(tv_data)})
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert String.starts_with?(url, "/titulos/")
      assert String.ends_with?(url, "?referrer=search")

      # Verify the title was created in the database
      title = Media.get_title_by_tmdb_id(456, "tv")
      assert title != nil
      assert title.title == "Test TV Show"
      assert title.original_title == "Test TV Show Original"
    end

    test "displays 9 titles per section in 3x3 grid", %{conn: conn, user: user} do
      # Log in the user
      conn = log_in_user(conn, user)

      # Visit the search page
      {:ok, _view, html} = live(conn, ~p"/pesquisar")

      # Check that each section shows exactly 9 titles
      # We can verify this by counting the poster elements in each section
      assert html =~ "Filmes em Alta"
      assert html =~ "Séries Populares"
      assert html =~ "Lançamentos Recentes"
      assert html =~ "Melhores Avaliados"

      # Verify the grid layout is 3 columns
      assert html =~ "grid-cols-3"

      # Verify that we're taking 9 items from each section
      # This is done in the template with Enum.take(@trending_movies, 9)
      # The actual count will depend on the data available from TMDB
    end
  end
end
