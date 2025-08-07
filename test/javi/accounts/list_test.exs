defmodule Javi.Accounts.ListTest do
  use Javi.DataCase

  alias Javi.Accounts.{List}
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

  describe "changeset/2" do
    test "changeset with valid attributes" do
      user = user_fixture()
      attrs = %{name: "My List", description: "A great list", user_id: user.id}
      changeset = List.changeset(%List{}, attrs)
      assert changeset.valid?
    end

    test "changeset requires name" do
      user = user_fixture()
      attrs = %{description: "A list without name", user_id: user.id}
      changeset = List.changeset(%List{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "changeset requires user_id" do
      attrs = %{name: "My List", description: "A list without user"}
      changeset = List.changeset(%List{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "changeset validates name length" do
      user = user_fixture()
      attrs = %{name: String.duplicate("a", 101), user_id: user.id}
      changeset = List.changeset(%List{}, attrs)
      refute changeset.valid?
      assert "should be at most 100 character(s)" in errors_on(changeset).name
    end

    test "changeset validates description length" do
      user = user_fixture()
      attrs = %{name: "My List", description: String.duplicate("a", 501), user_id: user.id}
      changeset = List.changeset(%List{}, attrs)
      refute changeset.valid?
      assert "should be at most 500 character(s)" in errors_on(changeset).description
    end

    test "changeset validates list_type inclusion" do
      user = user_fixture()
      attrs = %{name: "My List", list_type: "invalid_type", user_id: user.id}
      changeset = List.changeset(%List{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).list_type
    end

    test "changeset accepts valid list types" do
      user = user_fixture()
      valid_types = ["custom", "favorites", "watching", "watched", "want_to_watch"]

      for list_type <- valid_types do
        attrs = %{name: "My List", list_type: list_type, user_id: user.id}
        changeset = List.changeset(%List{}, attrs)
        assert changeset.valid?, "List type #{list_type} should be valid"
      end
    end
  end

  describe "create_changeset/2" do
    test "create_changeset with valid attributes" do
      user = user_fixture()
      attrs = %{name: "New List", description: "A new list", user_id: user.id}
      changeset = List.create_changeset(%List{}, attrs)
      assert changeset.valid?
    end

    test "create_changeset delegates to changeset/2" do
      user = user_fixture()
      attrs = %{name: "Test List", user_id: user.id}
      changeset = List.create_changeset(%List{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :name) == "Test List"
    end
  end

  describe "update_changeset/2" do
    test "update_changeset with valid attributes" do
      user = user_fixture()
      list = list_fixture(user, %{name: "Original Name"})
      attrs = %{name: "Updated Name", description: "Updated description"}
      changeset = List.update_changeset(list, attrs)
      assert changeset.valid?
      assert get_change(changeset, :name) == "Updated Name"
    end

    test "update_changeset delegates to changeset/2" do
      user = user_fixture()
      list = list_fixture(user, %{name: "Original Name"})
      attrs = %{name: "Updated Name"}
      changeset = List.update_changeset(list, attrs)
      assert changeset.valid?
      assert get_change(changeset, :name) == "Updated Name"
    end
  end

  describe "schema associations" do
    test "list belongs to user" do
      user = user_fixture()
      list = list_fixture(user)
      assert list.user_id == user.id
    end

    test "list has many list_items" do
      user = user_fixture()
      list = list_fixture(user)
      # This would be tested when we add list items
      assert list.list_items == %Ecto.Association.NotLoaded{
               __cardinality__: :many,
               __field__: :list_items,
               __owner__: Javi.Accounts.List
             }
    end

    test "list has many titles through list_items" do
      user = user_fixture()
      list = list_fixture(user)
      # This would be tested when we add titles to the list
      assert list.titles == %Ecto.Association.NotLoaded{
               __cardinality__: :many,
               __field__: :titles,
               __owner__: Javi.Accounts.List
             }
    end
  end

  describe "default values" do
    test "list has default is_public value" do
      user = user_fixture()
      list = list_fixture(user)
      assert list.is_public == false
    end

    test "list has default list_type value" do
      user = user_fixture()
      list = list_fixture(user)
      assert list.list_type == "custom"
    end
  end

  describe "timestamps" do
    test "list has timestamps" do
      user = user_fixture()
      list = list_fixture(user)
      assert list.inserted_at
      assert list.updated_at
    end
  end
end
