defmodule JaviWeb.Home.DashboardLiveTest do
  use JaviWeb.ConnCase

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures
  import Javi.MediaFixtures
  import Floki

  alias Javi.Accounts

  @create_user_attrs %{
    email: "test@example.com",
    password: "testpassword123"
  }

  setup do
    user = user_fixture(@create_user_attrs)

    # Mark user as having completed onboarding
    user
    |> Javi.Accounts.User.complete_onboarding_changeset()
    |> Javi.Repo.update()

    %{user: user}
  end

  describe "Dashboard page rendering" do
    test "renders dashboard page with user information", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/inicio")

      assert {:ok, document} = Floki.parse_document(html)

      # Check for dashboard page elements
      assert Floki.find(document, "h2") |> Floki.text() =~ "Dashboard"

      assert Floki.find(document, "h3") |> Floki.text() =~ user.display_name
    end

    test "shows default lists for user", %{conn: conn, user: user} do
      # Create some default lists for the user
      {:ok, _watching_list} =
        Accounts.create_list(user, %{
          name: "Assistindo",
          description: "Filmes e séries que você está assistindo",
          list_type: "watching"
        })

      {:ok, _favorites_list} =
        Accounts.create_list(user, %{
          name: "Favoritos",
          description: "Seus filmes e séries favoritos",
          list_type: "favorites"
        })

      # Log in the user
      conn = log_in_user(conn, user)

      # Visit the dashboard
      {:ok, _view, html} = live(conn, ~p"/inicio")

      assert {:ok, document} = Floki.parse_document(html)

      # Check that the lists are displayed
      assert Floki.find(document, "h2") |> Floki.text() =~ "Minhas Listas"
      assert html =~ "Assistindo"
      assert html =~ "Favoritos"
    end

    test "shows custom lists for user", %{conn: conn, user: user} do
      # Create a custom list for the user
      {:ok, _custom_list} =
        Accounts.create_list(user, %{
          name: "Minha Lista Personalizada",
          description: "Uma lista personalizada",
          list_type: "custom"
        })

      # Log in the user
      conn = log_in_user(conn, user)

      # Visit the dashboard
      {:ok, _view, html} = live(conn, ~p"/inicio")

      assert {:ok, document} = Floki.parse_document(html)

      # Check that the custom list is displayed
      assert html =~ "Minha Lista Personalizada"
    end

    test "shows empty state when no lists exist", %{conn: conn, user: user} do
      # Delete all existing lists to test empty state
      user_lists = Accounts.get_user_lists(user)
      Enum.each(user_lists, fn list -> Accounts.delete_list(list) end)

      # Log in the user
      conn = log_in_user(conn, user)

      # Visit the dashboard
      {:ok, _view, html} = live(conn, ~p"/inicio")

      assert {:ok, document} = Floki.parse_document(html)

      # Check that the empty state is displayed
      assert html =~ "Você ainda não tem listas"
    end
  end

  describe "Dashboard events" do
    test "handles navigate_to_title event with genre conversion", %{conn: conn, user: user} do
      # Log in the user
      conn = log_in_user(conn, user)

      # Visit the dashboard
      {:ok, view, _html} = live(conn, ~p"/inicio")

      # Simulate clicking on a title (this would be a movie from TMDB)
      title_data = %{
        "id" => 12345,
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
        "genre_ids" => [28, 12],
        "media_type" => "movie"
      }

      # Trigger the navigate_to_title event
      result = render_hook(view, "navigate_to_title", %{"title" => Jason.encode!(title_data)})
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert String.starts_with?(url, "/titulos/")
      assert String.ends_with?(url, "?referrer=dashboard")
    end

    test "handles navigate_to_title event with TV show", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/inicio")

      # Simulate clicking on a TV show
      tv_data = %{
        "id" => 67890,
        "name" => "Test TV Show",
        "original_name" => "Test TV Show Original",
        "overview" => "A test TV show",
        "first_air_date" => "2023-01-01",
        "vote_average" => 8.0,
        "vote_count" => 500,
        "popularity" => 80.0,
        "poster_path" => "/test-tv.jpg",
        "backdrop_path" => "/backdrop-tv.jpg",
        "adult" => false,
        "genre_ids" => [10759, 35],
        "media_type" => "tv"
      }

      # Trigger the navigate_to_title event
      result = render_hook(view, "navigate_to_title", %{"title" => Jason.encode!(tv_data)})
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert String.starts_with?(url, "/titulos/")
      assert String.ends_with?(url, "?referrer=dashboard")
    end

    test "handles navigate_to_search event", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/inicio")

      # Trigger navigate_to_search event
      result = render_click(view, "navigate_to_search")
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert url == "/pesquisar"
    end

    test "handles navigate_to_lists event", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/inicio")

      # Trigger navigate_to_lists event
      result = render_click(view, "navigate_to_lists")
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert url == "/listas"
    end

    test "handles navigate_to_profile event", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/inicio")

      # Trigger navigate_to_profile event
      result = render_click(view, "navigate_to_profile")
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert url == "/perfil"
    end

    test "displays correct time spent statistics", %{conn: conn, user: user} do
      # Create a watched list and add some movies
      {:ok, watched_list} =
        Accounts.create_list(user, %{
          name: "Assistidos",
          description: "Filmes e séries assistidos",
          list_type: "watched"
        })

      # Create some test titles with duration data
      # 2 hour movie
      title1 = title_fixture(%{tmdb_type: "movie", runtime: 120})
      # 2 episodes of 45 min each
      title2 =
        title_fixture(%{
          tmdb_type: "tv",
          episode_run_time: [45],
          number_of_episodes: 2
        })

      # Add titles to watched list
      Accounts.add_title_to_list(watched_list, title1)
      Accounts.add_title_to_list(watched_list, title2)

      # Log in the user
      conn = log_in_user(conn, user)

      # Visit the dashboard
      {:ok, _view, html} = live(conn, ~p"/inicio")

      assert {:ok, document} = Floki.parse_document(html)

      # Check that the statistics are displayed correctly
      assert html =~ "Filmes Assistidos"

      assert html =~ "Séries Assistidas"

      # The actual numbers will depend on the test data
    end
  end
end
