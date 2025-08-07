defmodule JaviWeb.Home.TitleDetailLiveTest do
  use JaviWeb.ConnCase

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures
  import Javi.MediaFixtures
  import Floki

  @create_attrs %{title: "Test Movie", tmdb_id: 123, tmdb_type: "movie"}

  setup do
    %{user: user_fixture(%{display_name: "Test User"})}
  end

  describe "Title detail page rendering" do
    test "shows title details", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      title = title_fixture(@create_attrs)

      {:ok, _view, html} = live(conn, ~p"/titulos/#{title.id}")

      assert {:ok, document} = Floki.parse_document(html)

      # Check title details are displayed
      assert Floki.find(document, "[data-testid=title-name]") |> Floki.text() =~ title.title
      assert Floki.find(document, "[data-testid=title-details]") |> Floki.text() =~ "Detalhes"
    end

    test "renders title poster and backdrop", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      title = title_fixture(@create_attrs)

      {:ok, _view, html} = live(conn, ~p"/titulos/#{title.id}")

      assert {:ok, document} = Floki.parse_document(html)

      # Check poster and backdrop images
      assert Floki.find(document, "[data-testid=title-poster]")
      assert Floki.find(document, "[data-testid=title-backdrop]")
    end

    test "renders title information", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      title = title_fixture(@create_attrs)

      {:ok, _view, html} = live(conn, ~p"/titulos/#{title.id}")

      assert {:ok, document} = Floki.parse_document(html)

      # Check title information sections
      assert Floki.find(document, "[data-testid=title-overview]")
      assert Floki.find(document, "[data-testid=title-rating]")
      assert Floki.find(document, "[data-testid=title-release-date]")
    end

    test "renders action buttons", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      title = title_fixture(@create_attrs)

      {:ok, _view, html} = live(conn, ~p"/titulos/#{title.id}")

      assert {:ok, document} = Floki.parse_document(html)

      # Check action buttons
      assert Floki.find(document, "[data-testid=add-to-watched-button]")
      assert Floki.find(document, "[data-testid=add-to-watching-button]")
      assert Floki.find(document, "[data-testid=add-to-favorites-button]")
    end

    test "renders navigation buttons", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      title = title_fixture(@create_attrs)

      {:ok, _view, html} = live(conn, ~p"/titulos/#{title.id}")

      assert {:ok, document} = Floki.parse_document(html)

      # Check navigation buttons
      assert Floki.find(document, "[data-testid=back-button]")
      assert Floki.find(document, "[data-testid=search-button]")
    end
  end

  describe "Title detail page events" do
    test "redirects to search when title not found", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      # Use a very large ID that won't exist in TMDB either
      assert {:error, {:live_redirect, %{to: "/pesquisar"}}} = live(conn, ~p"/titulos/999999999")
    end

    test "add_to_watched event adds title to watched list", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      title = title_fixture(@create_attrs)

      {:ok, view, _html} = live(conn, ~p"/titulos/#{title.id}")

      # Trigger add to watched event
      result = render_click(view, "add_to_watched")

      # Check success message
      assert result =~ "Adicionado à lista de assistidos"
    end

    test "add_to_watching event adds title to watching list", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      title = title_fixture(@create_attrs)

      {:ok, view, _html} = live(conn, ~p"/titulos/#{title.id}")

      # Trigger add to watching event
      result = render_click(view, "add_to_watching")

      # Check success message
      assert result =~ "Adicionado à lista de assistindo"
    end

    test "add_to_favorites event adds title to favorites list", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      title = title_fixture(@create_attrs)

      {:ok, view, _html} = live(conn, ~p"/titulos/#{title.id}")

      # Trigger add to favorites event
      result = render_click(view, "add_to_favorites")

      # Check success message
      assert result =~ "Adicionado aos favoritos"
    end

    test "navigate_back event redirects to previous page", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      title = title_fixture(@create_attrs)

      {:ok, view, _html} = live(conn, ~p"/titulos/#{title.id}")

      # Trigger navigate back event
      result = render_click(view, "navigate_back")
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert url == "/pesquisar"
    end

    test "navigate_to_search event redirects to search page", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      title = title_fixture(@create_attrs)

      {:ok, view, _html} = live(conn, ~p"/titulos/#{title.id}")

      # Trigger navigate to search event
      result = render_click(view, "navigate_to_search")
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert url == "/pesquisar"
    end
  end
end
