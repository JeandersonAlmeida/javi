defmodule JaviWeb.Home.ListDetailLiveTest do
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
    %{user: user_fixture(@create_user_attrs)}
  end

  describe "List detail page rendering" do
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
      {:ok, _view, html} = live(conn, ~p"/listas/#{list.id}")

      assert {:ok, document} = Floki.parse_document(html)

      # Check that the list details are displayed
      assert Floki.find(document, "[data-testid=list-name]") |> Floki.text() =~ "Test List"

      assert Floki.find(document, "[data-testid=list-description]") |> Floki.text() =~
               "A test list"

      assert Floki.find(document, "[data-testid=list-item-count]") |> Floki.text() =~ "0 itens"
    end

    test "renders list items when available", %{conn: conn, user: user} do
      # Create a list and add some titles
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      title1 = title_fixture(%{title: "Movie 1"})
      title2 = title_fixture(%{title: "Movie 2"})

      Accounts.add_title_to_list(list, title1)
      Accounts.add_title_to_list(list, title2)

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas/#{list.id}")

      assert {:ok, document} = Floki.parse_document(html)

      # Check list items are displayed
      assert Floki.find(document, "[data-testid=list-items]")
      assert Floki.find(document, "[data-testid=list-items]") |> Floki.text() =~ "Movie 1"
      assert Floki.find(document, "[data-testid=list-items]") |> Floki.text() =~ "Movie 2"
    end

    test "renders empty state when no items", %{conn: conn, user: user} do
      # Create an empty list
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Empty List",
          description: "An empty list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas/#{list.id}")

      assert {:ok, document} = Floki.parse_document(html)

      # Check empty state
      assert Floki.find(document, "[data-testid=empty-list]")

      assert Floki.find(document, "[data-testid=empty-list]") |> Floki.text() =~
               "Esta lista está vazia"
    end

    test "renders action buttons", %{conn: conn, user: user} do
      # Create a list
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas/#{list.id}")

      assert {:ok, document} = Floki.parse_document(html)

      # Check action buttons
      assert Floki.find(document, "[data-testid=add-item-button]")
      assert Floki.find(document, "[data-testid=edit-list-button]")
      assert Floki.find(document, "[data-testid=delete-list-button]")
    end

    test "renders navigation buttons", %{conn: conn, user: user} do
      # Create a list
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas/#{list.id}")

      assert {:ok, document} = Floki.parse_document(html)

      # Check navigation buttons
      assert Floki.find(document, "[data-testid=back-button]")
      assert Floki.find(document, "[data-testid=search-button]")
    end
  end

  describe "List detail functionality" do
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
      {:ok, view, _html} = live(conn, ~p"/listas/#{list.id}")

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
      result = render_click(view, "add_to_list", %{"title" => Jason.encode!(movie_data)})
      assert result =~ "Test List"

      # Verify the movie was added to the list
      updated_list = Accounts.get_user_list(user, list.id)
      assert length(updated_list.list_items) == 1
      assert List.first(updated_list.list_items).title.title == "Test Movie"
    end

    test "add_to_list event with TV show", %{conn: conn, user: user} do
      # Create a list for the user
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas/#{list.id}")

      # Mock TV show data
      tv_data = %{
        "id" => 456,
        "name" => "Test TV Show",
        "overview" => "A test TV show",
        "poster_path" => "/test-tv-poster.jpg",
        "first_air_date" => "2024-01-01",
        "vote_average" => 8.0,
        "popularity" => 80.0,
        "media_type" => "tv"
      }

      # Simulate adding TV show to list
      result = render_click(view, "add_to_list", %{"title" => Jason.encode!(tv_data)})
      assert result =~ "Test List"

      # Verify the TV show was added to the list
      updated_list = Accounts.get_user_list(user, list.id)
      assert length(updated_list.list_items) == 1
      assert List.first(updated_list.list_items).title.title == "Test TV Show"
    end

    test "remove_from_list event removes item", %{conn: conn, user: user} do
      # Create a list and add a title
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      title = title_fixture(%{title: "Test Movie"})
      Accounts.add_title_to_list(list, title)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas/#{list.id}")

      # Remove item from list
      result =
        render_click(view, "remove_from_list", %{
          "item_id" => list.list_items |> List.first() |> Map.get(:id)
        })

      assert result =~ "Test List"

      # Verify the item was removed from the list
      updated_list = Accounts.get_user_list(user, list.id)
      assert length(updated_list.list_items) == 0
    end

    test "navigate_back event redirects to lists page", %{conn: conn, user: user} do
      # Create a list
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas/#{list.id}")

      # Trigger navigate back event
      result = render_click(view, "navigate_back")
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert url == "/listas"
    end

    test "navigate_to_search event redirects to search page", %{conn: conn, user: user} do
      # Create a list
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas/#{list.id}")

      # Trigger navigate to search event
      result = render_click(view, "navigate_to_search")
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert url == "/pesquisar"
    end
  end
end
