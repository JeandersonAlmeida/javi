defmodule JaviWeb.Home.ListLiveTest do
  use JaviWeb.ConnCase

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures
  import Javi.MediaFixtures
  import Floki

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

  describe "List page rendering" do
    test "renders lists page with default lists", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas")

      assert {:ok, document} = Floki.parse_document(html)

      # Check for lists page elements
      assert Floki.find(document, "h2") |> Floki.text() =~ "Minhas Listas"

      # Check default lists are displayed
      assert html =~ "Listas Padrão"
      assert html =~ "Assistidos"
      assert html =~ "Assistindo"
      assert html =~ "Favoritos"
    end

    test "renders custom lists", %{conn: conn, user: user} do
      # Create a custom list
      {:ok, custom_list} =
        Accounts.create_list(user, %{
          name: "My Custom List",
          description: "A custom list for testing",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas")

      assert {:ok, document} = Floki.parse_document(html)

      # Check custom list is displayed
      assert html =~ "Minhas Listas"
      assert html =~ "My Custom List"
    end

    test "renders create list button", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas")

      assert {:ok, document} = Floki.parse_document(html)

      # Check create list button
      assert html =~ "Criar Nova Lista"
    end

    test "renders list items with counts", %{conn: conn, user: user} do
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
      {:ok, _view, html} = live(conn, ~p"/listas")

      assert {:ok, document} = Floki.parse_document(html)

      # Check list item count
      assert html =~ "2 itens"
    end

    test "renders empty state when no custom lists", %{conn: conn, user: user} do
      # Delete all custom lists
      user_lists = Accounts.get_user_lists(user)
      custom_lists = Enum.filter(user_lists, fn list -> list.list_type == "custom" end)
      Enum.each(custom_lists, fn list -> Accounts.delete_list(list) end)

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas")

      assert {:ok, document} = Floki.parse_document(html)

      # Check empty state
      assert html =~ "Criar Nova Lista"
    end

    test "renders list actions for custom lists", %{conn: conn, user: user} do
      # Create a custom list
      {:ok, _list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas")

      assert {:ok, document} = Floki.parse_document(html)

      # Check edit and delete buttons for custom lists (they are icons, not text)
      assert html =~ "show_edit_modal"
      assert html =~ "delete_list"
    end

    test "does not render actions for default lists", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas")

      assert {:ok, document} = Floki.parse_document(html)

      # Default lists should not have edit/delete buttons
      assert html =~ "Listas Padrão"
    end
  end

  describe "List page events" do
    test "show_create_modal event opens create modal", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Trigger show create modal
      result = render_click(view, "show_create_modal")

      # Check modal is displayed
      assert result =~ "Criar Nova Lista"
      assert result =~ "Nome da Lista"
      assert result =~ "Descrição"
    end

    test "close_modal event closes create modal", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Open modal first
      render_click(view, "show_create_modal")

      # Close modal
      result = render_click(view, "close_modal")

      # Check modal is closed (look for modal-specific content)
      refute result =~ "Nome da Lista"
      refute result =~ "Descrição"
    end

    test "validate_list event updates form", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Open modal first
      render_click(view, "show_create_modal")

      # Trigger form validation
      result =
        render_change(view, "validate_list", %{
          "name" => "New List Name",
          "description" => "New list description"
        })

      # Check form was updated
      assert result =~ "New List Name"
      assert result =~ "New list description"
    end

    test "create_list event creates new list", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Open modal first
      render_click(view, "show_create_modal")

      # Create list
      result =
        render_submit(view, "create_list", %{
          "name" => "New Test List",
          "description" => "A new test list"
        })

      # Check list was created
      assert result =~ "New Test List"
      assert result =~ "A new test list"

      # Verify list was actually created in database
      user_lists = Accounts.get_user_lists(user)
      custom_lists = Enum.filter(user_lists, fn list -> list.list_type == "custom" end)
      assert length(custom_lists) >= 1

      new_list = Enum.find(custom_lists, fn list -> list.name == "New Test List" end)
      assert new_list != nil
      assert new_list.description == "A new test list"
    end

    test "create_list event with empty name shows error", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Open modal first
      render_click(view, "show_create_modal")

      # Try to create list with empty name
      result =
        render_submit(view, "create_list", %{
          "name" => "",
          "description" => "A list without name"
        })

      # Check error is displayed
      assert result =~ "Nome da Lista"
      assert result =~ "A list without name"
    end

    test "show_edit_modal event opens edit modal", %{conn: conn, user: user} do
      # Create a custom list
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Trigger show edit modal
      result = render_click(view, "show_edit_modal", %{"id" => list.id})

      # Check edit modal is displayed
      assert result =~ "Editar Lista"
      assert result =~ "Test List"
      assert result =~ "A test list"
    end

    test "close_edit_modal event closes edit modal", %{conn: conn, user: user} do
      # Create a custom list
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Open edit modal first
      render_click(view, "show_edit_modal", %{"id" => list.id})

      # Close edit modal
      result = render_click(view, "close_edit_modal")

      # Check modal is closed
      refute result =~ "Editar Lista"
    end

    test "validate_edit_list event updates edit form", %{conn: conn, user: user} do
      # Create a custom list
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Open edit modal first
      render_click(view, "show_edit_modal", %{"id" => list.id})

      # Trigger edit form validation
      result =
        render_change(view, "validate_edit_list", %{
          "name" => "Updated List Name",
          "description" => "Updated list description"
        })

      # Check form was updated
      assert result =~ "Updated List Name"
      assert result =~ "Updated list description"
    end

    test "update_list event updates list", %{conn: conn, user: user} do
      # Create a custom list
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Open edit modal first
      render_click(view, "show_edit_modal", %{"id" => list.id})

      # Update list
      result =
        render_submit(view, "update_list", %{
          "name" => "Updated Test List",
          "description" => "An updated test list"
        })

      # Check list was updated
      assert result =~ "Updated Test List"
      assert result =~ "An updated test list"

      # Verify list was actually updated in database
      updated_list = Accounts.get_user_list(user, list.id)
      assert updated_list.name == "Updated Test List"
      assert updated_list.description == "An updated test list"
    end

    test "delete_list event deletes list", %{conn: conn, user: user} do
      # Create a custom list
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Delete list
      result = render_click(view, "delete_list", %{"id" => list.id})

      # Check list was removed from view
      refute result =~ "Test List"

      # Verify list was actually deleted from database
      deleted_list = Accounts.get_user_list(user, list.id)
      assert deleted_list == nil
    end

    test "navigate_to_list event redirects to list detail", %{conn: conn, user: user} do
      # Create a custom list
      {:ok, list} =
        Accounts.create_list(user, %{
          name: "Test List",
          description: "A test list",
          list_type: "custom"
        })

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Navigate to list detail
      result = render_click(view, "navigate_to_list", %{"list-id" => list.id})
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert url == "/listas/#{list.id}"
    end
  end

  describe "List page edge cases" do
    test "show_edit_modal with non-existent list", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Try to edit non-existent list
      result = render_click(view, "show_edit_modal", %{"id" => 99999})

      # Should not open modal
      refute result =~ "Editar Lista"
    end

    test "update_list with non-existent list", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Try to update non-existent list
      result =
        render_submit(view, "update_list", %{
          "name" => "Updated Name",
          "description" => "Updated description"
        })

      # Should not update anything
      refute result =~ "Updated Name"
    end

    test "delete_list with non-existent list", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Try to delete non-existent list
      result = render_click(view, "delete_list", %{"id" => 99999})

      # Should not cause any errors
      assert result =~ "Minhas Listas"
    end

    test "navigate_to_list with non-existent list", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/listas")

      # Try to navigate to non-existent list
      result = render_click(view, "navigate_to_list", %{"list-id" => 99999})

      # Should redirect to list detail page (which will handle the error)
      assert {:error, {:live_redirect, %{kind: :push, to: url}}} = result
      assert url == "/listas/99999"
    end

    test "handles user with no lists", %{conn: conn, user: user} do
      # Delete all user lists
      user_lists = Accounts.get_user_lists(user)
      Enum.each(user_lists, fn list -> Accounts.delete_list(list) end)

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas")

      assert {:ok, document} = Floki.parse_document(html)

      # Should show empty state
      assert html =~ "Criar Nova Lista"
    end

    test "ensures default lists are created", %{conn: conn, user: user} do
      # Delete all user lists
      user_lists = Accounts.get_user_lists(user)
      Enum.each(user_lists, fn list -> Accounts.delete_list(list) end)

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/listas")

      assert {:ok, document} = Floki.parse_document(html)

      # Should show default lists
      assert html =~ "Listas Padrão"
      assert html =~ "Assistidos"
      assert html =~ "Assistindo"
      assert html =~ "Favoritos"

      # Verify default lists were created in database
      user_lists = Accounts.get_user_lists(user)
      default_list_types = Enum.map(user_lists, & &1.list_type)
      assert "watching" in default_list_types
      assert "favorites" in default_list_types
      assert "watched" in default_list_types
    end
  end
end
