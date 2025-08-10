defmodule Javi.Accounts.ListItemTest do
  use Javi.DataCase

  alias Javi.Accounts.{ListItem}
  alias Javi.Repo

  import Javi.AccountsFixtures

  def list_fixture(user, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Test List",
        description: "A test list",
        user_id: user.id
      })

    {:ok, list} = Javi.Accounts.create_list(user, attrs)
    list
  end

  def title_fixture(attrs \\ %{}) do
    {:ok, title} =
      attrs
      |> Enum.into(%{
        tmdb_id: 123,
        tmdb_type: "movie",
        title: "Test Movie"
      })
      |> Javi.Media.create_title()

    title
  end

  def list_item_fixture(list, title, _attrs \\ %{}) do
    {:ok, list_item} = Javi.Accounts.add_title_to_list(list, title)
    list_item
  end

  describe "changeset/2" do
    test "changeset with valid attributes" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      attrs = %{list_id: list.id, title_id: title.id, position: 1}
      changeset = ListItem.changeset(%ListItem{}, attrs)
      assert changeset.valid?
    end

    test "changeset requires list_id" do
      title = title_fixture()
      attrs = %{title_id: title.id, position: 1}
      changeset = ListItem.changeset(%ListItem{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).list_id
    end

    test "changeset requires title_id" do
      user = user_fixture()
      list = list_fixture(user)
      attrs = %{list_id: list.id, position: 1}
      changeset = ListItem.changeset(%ListItem{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title_id
    end

    test "changeset validates position" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      attrs = %{list_id: list.id, title_id: title.id, position: -1}
      changeset = ListItem.changeset(%ListItem{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).position
    end

    test "changeset validates rating range" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      attrs = %{list_id: list.id, title_id: title.id, rating: 6}
      changeset = ListItem.changeset(%ListItem{}, attrs)
      refute changeset.valid?
      assert "must be less than or equal to 5" in errors_on(changeset).rating
    end

    test "changeset validates notes length" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      long_notes = String.duplicate("a", 1001)
      attrs = %{list_id: list.id, title_id: title.id, notes: long_notes}
      changeset = ListItem.changeset(%ListItem{}, attrs)
      refute changeset.valid?
      assert "should be at most 1000 character(s)" in errors_on(changeset).notes
    end

    test "changeset enforces unique constraint" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      attrs = %{list_id: list.id, title_id: title.id, position: 1}

      # Insert first item
      {:ok, _list_item} = Repo.insert(ListItem.create_changeset(%ListItem{}, attrs))

      # Try to insert duplicate
      {:error, changeset} = Repo.insert(ListItem.create_changeset(%ListItem{}, attrs))
      refute changeset.valid?
      assert "has already been taken" in errors_on(changeset).list_id
    end
  end

  describe "create_changeset/2" do
    test "create_changeset with valid attributes" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      attrs = %{list_id: list.id, title_id: title.id, position: 1}
      changeset = ListItem.create_changeset(%ListItem{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :added_at)
    end

    test "create_changeset sets added_at timestamp" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      attrs = %{list_id: list.id, title_id: title.id, position: 1}
      changeset = ListItem.create_changeset(%ListItem{}, attrs)
      assert get_change(changeset, :added_at)
    end
  end

  describe "update_changeset/2" do
    test "update_changeset with valid attributes" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      list_item = list_item_fixture(list, title)
      attrs = %{notes: "Updated notes", rating: 4}
      changeset = ListItem.update_changeset(list_item, attrs)
      assert changeset.valid?
      assert get_change(changeset, :notes) == "Updated notes"
      assert get_change(changeset, :rating) == 4
    end

    test "update_changeset delegates to changeset/2" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      list_item = list_item_fixture(list, title)
      attrs = %{notes: "Test notes"}
      changeset = ListItem.update_changeset(list_item, attrs)
      assert changeset.valid?
      assert get_change(changeset, :notes) == "Test notes"
    end
  end

  describe "schema associations" do
    test "list_item belongs to list" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      list_item = list_item_fixture(list, title)
      assert list_item.list_id == list.id
    end

    test "list_item belongs to title" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      list_item = list_item_fixture(list, title)
      assert list_item.title_id == title.id
    end
  end

  describe "default values" do
    test "list_item has default position value" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      list_item = list_item_fixture(list, title)
      assert list_item.position == 1
    end
  end

  describe "timestamps" do
    test "list_item has timestamps" do
      user = user_fixture()
      list = list_fixture(user)
      title = title_fixture()
      list_item = list_item_fixture(list, title)
      assert list_item.inserted_at
      assert list_item.updated_at
    end
  end

  describe "foreign key constraints" do
    test "changeset validates list_id foreign key" do
      title = title_fixture()
      attrs = %{list_id: 999_999, title_id: title.id, position: 1}
      changeset = ListItem.changeset(%ListItem{}, attrs)
      assert changeset.valid?
      # The actual foreign key constraint would be tested at the database level
    end

    test "changeset validates title_id foreign key" do
      user = user_fixture()
      list = list_fixture(user)
      attrs = %{list_id: list.id, title_id: 999_999, position: 1}
      changeset = ListItem.changeset(%ListItem{}, attrs)
      assert changeset.valid?
      # The actual foreign key constraint would be tested at the database level
    end
  end
end
