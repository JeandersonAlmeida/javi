defmodule JaviWeb.Home.ListDetailLiveTest do
  use JaviWeb.ConnCase

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures

  alias Javi.Accounts

  @create_user_attrs %{
    email: "test@example.com",
    password: "testpassword123"
  }

  setup do
    %{user: user_fixture(@create_user_attrs)}
  end

  describe "List detail functionality" do
    test "shows list details", %{conn: conn, user: user} do
      # Create a list for the user
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      # Log in the user
      conn = log_in_user(conn, user)

      # Visit the list detail page
      {:ok, _view, html} = live(conn, ~p"/lists/#{list.id}")

      # Check that the list details are displayed
      assert html =~ "Test List"
      assert html =~ "A test list"
      assert html =~ "0 itens"
    end

    test "can add movie to list", %{conn: conn, user: user} do
      # Create a list for the user
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      # Log in the user
      conn = log_in_user(conn, user)

      # Visit the list detail page
      {:ok, view, _html} = live(conn, ~p"/lists/#{list.id}")

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

      # Simulate adding movie to list
      assert render_click(view, "add_to_list", %{"title" => Jason.encode!(movie_data)}) =~
               "Test List"

      # Verify the movie was added to the list
      updated_list = Accounts.get_user_list(user, list.id)
      assert length(updated_list.list_items) == 1
      assert List.first(updated_list.list_items).title.title == "Test Movie"
    end
  end
end
