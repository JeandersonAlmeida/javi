defmodule JaviWeb.Home.ProfileLiveTest do
  use JaviWeb.ConnCase

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures
  import Javi.MediaFixtures

  alias Javi.Accounts

  @create_user_attrs %{
    email: "test@example.com",
    password: "testpassword123",
    display_name: "Test User"
  }

  setup do
    user = user_fixture(@create_user_attrs)

    # Mark user as having completed onboarding
    user
    |> Javi.Accounts.User.complete_onboarding_changeset()
    |> Javi.Repo.update()

    %{user: user}
  end

  describe "Profile page rendering" do
    test "renders profile page with user information", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/perfil")

      # Test with Floki for better HTML parsing
      assert {:ok, document} = Floki.parse_document(html)

      # Check for user information
      assert Floki.find(document, "h2") |> Floki.text() =~ "Perfil"
      assert html =~ user.display_name
      assert html =~ user.email
    end

    test "renders user statistics correctly", %{conn: conn, user: user} do
      # Create some test data
      title1 = title_fixture(%{tmdb_type: "movie", runtime: 120})
      title2 = title_fixture(%{tmdb_type: "tv", episode_run_time: [45], number_of_episodes: 2})

      # Add titles to user's watched list
      watched_list = Accounts.get_user_watched_list(user)
      Accounts.add_title_to_list(watched_list, title1)
      Accounts.add_title_to_list(watched_list, title2)

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/perfil")

      # Check statistics are displayed
      assert html =~ "Estatísticas"
      assert html =~ "Total Assistido"
      assert html =~ "Tempo Gasto"
    end

    test "renders recent watched titles", %{conn: conn, user: user} do
      # Create and add a watched title
      title = title_fixture(%{title: "Test Movie", tmdb_type: "movie"})
      watched_list = Accounts.get_user_watched_list(user)
      Accounts.add_title_to_list(watched_list, title)

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/perfil")

      # Check recent watched section
      assert html =~ "Atividades Recentes"
      assert html =~ "Test Movie"
    end

    test "renders empty state when no watched titles", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/perfil")

      # Check empty state
      assert html =~ "Nenhuma atividade recente"
      assert html =~ "Explorar Filmes"
    end

    test "renders navigation elements", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/perfil")

      # Check navigation elements exist
      assert html =~ "Menu"
      assert html =~ "Sair"
    end
  end

  describe "Profile page events" do
    test "navigate_to_search event redirects to search page", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/perfil")

      # Trigger navigate_to_search event
      result = render_click(view, "navigate_to_search")
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert url == "/pesquisar"
    end

    test "logout event redirects to logout page", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/perfil")

      # Trigger logout event
      result = render_click(view, "logout")
      assert {:error, {:redirect, %{to: url}}} = result
      assert url == "/sair"
    end
  end

  describe "Profile page with different user states" do
    test "handles user with no statistics", %{conn: conn, user: user} do
      # Ensure user has no watched titles
      watched_list = Accounts.get_user_watched_list(user)
      list_items = Accounts.get_list_items(watched_list)
      Enum.each(list_items, fn item -> Accounts.delete_list_item(item) end)

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/perfil")

      # Check default statistics
      assert html =~ "0"
    end

    test "handles user with preferred genres", %{conn: conn, user: user} do
      # Update user with preferred genres
      user
      |> Ecto.Changeset.change(%{preferred_genres: ["Action", "Drama"]})
      |> Javi.Repo.update()

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/perfil")

      # Check that the page loads correctly
      assert html =~ "Perfil"
    end

    test "handles user without preferred genres", %{conn: conn, user: user} do
      # Ensure user has no preferred genres
      user
      |> Ecto.Changeset.change(%{preferred_genres: nil})
      |> Javi.Repo.update()

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/perfil")

      # Check that the page loads correctly
      assert html =~ "Perfil"
    end
  end

  describe "Profile page edge cases" do
    test "handles user with nil session token", %{conn: conn} do
      # Test with no user session
      assert {:error, {:redirect, %{to: "/entrar"}}} = live(conn, ~p"/perfil")
    end

    test "handles user with invalid session token", %{conn: conn} do
      # Test with invalid session
      conn = fetch_session(conn)
      conn = put_session(conn, :user_token, "invalid_token")
      assert {:error, {:redirect, %{to: "/entrar"}}} = live(conn, ~p"/perfil")
    end
  end
end
