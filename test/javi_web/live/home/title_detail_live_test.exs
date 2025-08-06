defmodule JaviWeb.Home.TitleDetailLiveTest do
  use JaviWeb.ConnCase

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures
  import Javi.MediaFixtures

  @create_attrs %{title: "Test Movie", tmdb_id: 123, tmdb_type: "movie"}

  setup do
    %{user: user_fixture(%{display_name: "Test User"})}
  end

  describe "Title detail page" do
    test "shows title details", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      title = title_fixture(@create_attrs)

      {:ok, _view, html} = live(conn, ~p"/titles/#{title.id}")

      assert html =~ title.title
      assert html =~ "Detalhes"
    end

    test "redirects to search when title not found", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      # Use a very large ID that won't exist in TMDB either
      assert {:error, {:live_redirect, %{to: "/search"}}} = live(conn, ~p"/titles/999999999")
    end
  end
end
