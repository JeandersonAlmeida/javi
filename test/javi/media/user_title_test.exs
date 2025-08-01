defmodule Javi.Media.UserTitleTest do
  use Javi.DataCase

  alias Javi.Media.UserTitle

  @valid_attrs %{
    status: :watching,
    rating: 8,
    notes: "Great movie!",
    date_watched: ~D[2023-01-15],
    date_started: ~D[2023-01-10],
    date_completed: ~D[2023-01-20],
    episodes_watched: 5,
    total_episodes: 10,
    rewatch_count: 1,
    is_private: false
  }

  @invalid_attrs %{
    status: nil,
    user_id: nil,
    title_id: nil
  }

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "test@example.com",
        password: "testpassword123"
      })
      |> Javi.Accounts.register_user()

    user
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

  def user_title_fixture(attrs \\ %{}) do
    user = user_fixture()
    title = title_fixture()

    {:ok, user_title} =
      attrs
      |> Enum.into(%{user_id: user.id, title_id: title.id})
      |> Javi.Media.create_user_title()

    user_title
  end

  describe "changeset/2" do
    test "changeset with valid attributes" do
      user = user_fixture()
      title = title_fixture()
      attrs = Map.merge(@valid_attrs, %{user_id: user.id, title_id: title.id})

      changeset = UserTitle.changeset(%UserTitle{}, attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = UserTitle.changeset(%UserTitle{}, @invalid_attrs)
      refute changeset.valid?
    end

    test "changeset validates required fields" do
      changeset = UserTitle.changeset(%UserTitle{}, %{})

      assert %{
               status: ["can't be blank"],
               user_id: ["can't be blank"],
               title_id: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "changeset validates rating range" do
      user = user_fixture()
      title = title_fixture()
      attrs = Map.merge(@valid_attrs, %{user_id: user.id, title_id: title.id, rating: 11})

      changeset = UserTitle.changeset(%UserTitle{}, attrs)
      assert %{rating: ["must be less than or equal to 10"]} = errors_on(changeset)

      attrs = Map.merge(@valid_attrs, %{user_id: user.id, title_id: title.id, rating: 0})
      changeset = UserTitle.changeset(%UserTitle{}, attrs)
      assert %{rating: ["must be greater than or equal to 1"]} = errors_on(changeset)
    end

    test "changeset validates episodes_watched" do
      user = user_fixture()
      title = title_fixture()

      attrs =
        Map.merge(@valid_attrs, %{user_id: user.id, title_id: title.id, episodes_watched: -1})

      changeset = UserTitle.changeset(%UserTitle{}, attrs)
      assert %{episodes_watched: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset validates total_episodes" do
      user = user_fixture()
      title = title_fixture()
      attrs = Map.merge(@valid_attrs, %{user_id: user.id, title_id: title.id, total_episodes: -1})

      changeset = UserTitle.changeset(%UserTitle{}, attrs)
      assert %{total_episodes: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset validates episodes_watched vs total_episodes" do
      user = user_fixture()
      title = title_fixture()

      attrs =
        Map.merge(@valid_attrs, %{
          user_id: user.id,
          title_id: title.id,
          episodes_watched: 15,
          total_episodes: 10
        })

      changeset = UserTitle.changeset(%UserTitle{}, attrs)
      assert %{episodes_watched: ["cannot be greater than total episodes"]} = errors_on(changeset)
    end

    test "changeset validates rewatch_count" do
      user = user_fixture()
      title = title_fixture()
      attrs = Map.merge(@valid_attrs, %{user_id: user.id, title_id: title.id, rewatch_count: -1})

      changeset = UserTitle.changeset(%UserTitle{}, attrs)
      assert %{rewatch_count: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset validates dates" do
      user = user_fixture()
      title = title_fixture()

      attrs =
        Map.merge(@valid_attrs, %{
          user_id: user.id,
          title_id: title.id,
          date_started: ~D[2023-01-20],
          date_completed: ~D[2023-01-10]
        })

      changeset = UserTitle.changeset(%UserTitle{}, attrs)
      assert %{date_completed: ["cannot be before start date"]} = errors_on(changeset)
    end
  end

  describe "watched_changeset/2" do
    test "watched_changeset with valid attributes" do
      user = user_fixture()
      title = title_fixture()
      attrs = %{rating: 9, notes: "Great movie!", date_watched: ~D[2023-01-15]}

      changeset =
        UserTitle.watched_changeset(
          %UserTitle{},
          Map.merge(attrs, %{user_id: user.id, title_id: title.id})
        )

      assert changeset.valid?
      assert get_change(changeset, :status) == :watched
    end

    test "watched_changeset requires date_watched" do
      user = user_fixture()
      title = title_fixture()
      attrs = %{rating: 9, notes: "Great movie!"}

      changeset =
        UserTitle.watched_changeset(
          %UserTitle{},
          Map.merge(attrs, %{user_id: user.id, title_id: title.id})
        )

      assert %{date_watched: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "watching_changeset/2" do
    test "watching_changeset with valid attributes" do
      user = user_fixture()
      title = title_fixture()
      attrs = %{episodes_watched: 5, total_episodes: 10, notes: "Great show!"}

      changeset =
        UserTitle.watching_changeset(
          %UserTitle{},
          Map.merge(attrs, %{user_id: user.id, title_id: title.id})
        )

      assert changeset.valid?
      assert get_change(changeset, :status) == :watching
    end
  end

  describe "want_to_watch_changeset/2" do
    test "want_to_watch_changeset with valid attributes" do
      user = user_fixture()
      title = title_fixture()
      attrs = %{notes: "Want to watch this!"}

      changeset =
        UserTitle.want_to_watch_changeset(
          %UserTitle{},
          Map.merge(attrs, %{user_id: user.id, title_id: title.id})
        )

      assert changeset.valid?
      assert get_change(changeset, :status) == :want_to_watch
    end
  end

  describe "favorite_changeset/2" do
    test "favorite_changeset with valid attributes" do
      user = user_fixture()
      title = title_fixture()
      attrs = %{notes: "One of my favorites!"}

      changeset =
        UserTitle.favorite_changeset(
          %UserTitle{},
          Map.merge(attrs, %{user_id: user.id, title_id: title.id})
        )

      assert changeset.valid?
      assert get_change(changeset, :status) == :favorite
    end
  end

  describe "get_by_status/2" do
    test "returns query for user titles by status" do
      query = UserTitle.get_by_status(1, :watching)
      assert query.from.source == {"user_titles", UserTitle}
    end
  end

  describe "get_by_user/1" do
    test "returns query for user titles by user" do
      query = UserTitle.get_by_user(1)
      assert query.from.source == {"user_titles", UserTitle}
    end
  end

  describe "get_by_user_and_title/2" do
    test "returns query for user title by user and title" do
      query = UserTitle.get_by_user_and_title(1, 1)
      assert query.from.source == {"user_titles", UserTitle}
    end
  end

  describe "get_with_ratings/1" do
    test "returns query for user titles with ratings" do
      query = UserTitle.get_with_ratings(1)
      assert query.from.source == {"user_titles", UserTitle}
    end
  end

  describe "get_recently_watched/2" do
    test "returns query for recently watched titles" do
      query = UserTitle.get_recently_watched(1, 10)
      assert query.from.source == {"user_titles", UserTitle}
    end
  end

  describe "get_user_stats/1" do
    test "returns query for user statistics" do
      query = UserTitle.get_user_stats(1)
      assert query.from.source == {"user_titles", UserTitle}
    end
  end
end
