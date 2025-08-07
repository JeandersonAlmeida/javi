defmodule Javi.MediaTest do
  use Javi.DataCase

  alias Javi.Media
  alias Javi.Media.{Title, UserTitle}

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "test#{System.unique_integer()}@example.com",
        password: "testpassword123",
        display_name: "Test User"
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
        title: "Test Movie",
        overview: "A test movie",
        release_date: ~D[2023-01-01],
        vote_average: Decimal.new("8.5"),
        vote_count: 1000,
        popularity: Decimal.new("85.5"),
        poster_path: "/test-poster.jpg",
        backdrop_path: "/test-backdrop.jpg",
        adult: false,
        genres: ["Action", "Drama"]
      })
      |> Media.create_title()

    title
  end

  def user_title_fixture(attrs \\ %{}) do
    user = user_fixture()
    title = title_fixture()

    {:ok, user_title} =
      attrs
      |> Enum.into(%{user_id: user.id, title_id: title.id, status: :watching})
      |> Media.create_user_title()

    user_title
  end

  describe "titles" do
    test "create_title/1 with valid data creates a title" do
      valid_attrs = %{
        tmdb_id: 123,
        tmdb_type: "movie",
        title: "Test Movie",
        overview: "A test movie",
        release_date: ~D[2023-01-01],
        vote_average: Decimal.new("8.5"),
        vote_count: 1000,
        popularity: Decimal.new("85.5"),
        poster_path: "/test-poster.jpg",
        backdrop_path: "/test-backdrop.jpg",
        adult: false,
        genres: ["Action", "Drama"]
      }

      assert {:ok, %Title{} = title} = Media.create_title(valid_attrs)
      assert title.tmdb_id == 123
      assert title.tmdb_type == "movie"
      assert title.title == "Test Movie"
      assert title.overview == "A test movie"
      assert title.release_date == ~D[2023-01-01]
      assert Decimal.eq?(title.vote_average, Decimal.new("8.5"))
      assert title.vote_count == 1000
      assert Decimal.eq?(title.popularity, Decimal.new("85.5"))
      assert title.poster_path == "/test-poster.jpg"
      assert title.backdrop_path == "/test-backdrop.jpg"
      assert title.adult == false
      assert title.genres == ["Action", "Drama"]
      assert title.last_updated_at
    end

    test "create_title/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Media.create_title(%{tmdb_id: nil})
    end

    test "get_title_by_tmdb_id/2 returns the title with given tmdb_id and tmdb_type" do
      title = title_fixture()
      fetched_title = Media.get_title_by_tmdb_id(title.tmdb_id, title.tmdb_type)
      assert fetched_title.id == title.id
      assert fetched_title.tmdb_id == title.tmdb_id
      assert fetched_title.tmdb_type == title.tmdb_type
    end

    test "get_title_by_tmdb_id/2 returns nil for non-existent title" do
      assert Media.get_title_by_tmdb_id(999, "movie") == nil
    end

    test "update_title/2 with valid data updates the title" do
      title = title_fixture()
      update_attrs = %{title: "Updated Movie", overview: "Updated overview"}

      assert {:ok, %Title{} = updated_title} = Media.update_title(title, update_attrs)
      assert updated_title.title == "Updated Movie"
      assert updated_title.overview == "Updated overview"
    end

    test "update_title/2 with invalid data returns error changeset" do
      title = title_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Media.update_title(title, %{vote_average: Decimal.new("11.0")})
    end

    test "get_or_create_title/3 creates title if it doesn't exist" do
      attrs = %{title: "New Movie", overview: "New movie overview"}
      assert {:ok, %Title{} = title} = Media.get_or_create_title(999, "movie", attrs)
      assert title.tmdb_id == 999
      assert title.tmdb_type == "movie"
      assert title.title == "New Movie"
    end

    test "get_or_create_title/3 returns existing title" do
      title = title_fixture()
      attrs = %{title: "Updated Movie"}

      assert {:ok, existing_title} =
               Media.get_or_create_title(title.tmdb_id, title.tmdb_type, attrs)

      assert existing_title.id == title.id
    end

    test "upsert_title/3 creates title if it doesn't exist" do
      attrs = %{title: "New Movie", overview: "New movie overview"}
      assert {:ok, %Title{} = title} = Media.upsert_title(999, "movie", attrs)
      assert title.tmdb_id == 999
      assert title.tmdb_type == "movie"
    end

    test "upsert_title/3 updates existing title" do
      title = title_fixture()
      update_attrs = %{title: "Updated Movie", overview: "Updated overview"}

      assert {:ok, updated_title} =
               Media.upsert_title(title.tmdb_id, title.tmdb_type, update_attrs)

      assert updated_title.id == title.id
      assert updated_title.title == "Updated Movie"
    end
  end

  describe "user_titles" do
    test "create_user_title/1 with valid data creates a user_title" do
      user = user_fixture()
      title = title_fixture()

      valid_attrs = %{
        user_id: user.id,
        title_id: title.id,
        status: :watching,
        rating: 8,
        notes: "Great movie!",
        episodes_watched: 5,
        total_episodes: 10
      }

      assert {:ok, %UserTitle{} = user_title} = Media.create_user_title(valid_attrs)
      assert user_title.user_id == user.id
      assert user_title.title_id == title.id
      assert user_title.status == :watching
      assert user_title.rating == 8
      assert user_title.notes == "Great movie!"
      assert user_title.episodes_watched == 5
      assert user_title.total_episodes == 10
    end

    test "create_user_title/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Media.create_user_title(%{status: nil})
    end

    test "get_user_title/2 returns the user_title with given user_id and title_id" do
      user_title = user_title_fixture()
      fetched_user_title = Media.get_user_title(user_title.user_id, user_title.title_id)
      assert fetched_user_title.id == user_title.id
      assert fetched_user_title.user_id == user_title.user_id
      assert fetched_user_title.title_id == user_title.title_id
    end

    test "get_user_title/2 returns nil for non-existent user_title" do
      user = user_fixture()
      title = title_fixture()
      assert Media.get_user_title(user.id, title.id) == nil
    end

    test "update_user_title/2 with valid data updates the user_title" do
      user_title = user_title_fixture()
      update_attrs = %{rating: 9, notes: "Updated notes"}

      assert {:ok, %UserTitle{} = updated_user_title} =
               Media.update_user_title(user_title, update_attrs)

      assert updated_user_title.rating == 9
      assert updated_user_title.notes == "Updated notes"
    end

    test "update_user_title/2 with invalid data returns error changeset" do
      user_title = user_title_fixture()
      assert {:error, %Ecto.Changeset{}} = Media.update_user_title(user_title, %{rating: 11})
    end

    test "upsert_user_title/3 creates user_title if it doesn't exist" do
      user = user_fixture()
      title = title_fixture()
      attrs = %{status: :watching, rating: 8, notes: "Great movie!"}

      assert {:ok, %UserTitle{} = user_title} = Media.upsert_user_title(user.id, title.id, attrs)
      assert user_title.user_id == user.id
      assert user_title.title_id == title.id
      assert user_title.status == :watching
    end

    test "upsert_user_title/3 updates existing user_title" do
      user_title = user_title_fixture()
      update_attrs = %{rating: 9, notes: "Updated notes"}

      assert {:ok, updated_user_title} =
               Media.upsert_user_title(user_title.user_id, user_title.title_id, update_attrs)

      assert updated_user_title.id == user_title.id
      assert updated_user_title.rating == 9
    end

    test "mark_as_watched/3 creates watched user_title" do
      user = user_fixture()
      title = title_fixture()
      attrs = %{rating: 9, notes: "Great movie!", date_watched: ~D[2023-01-15]}

      assert {:ok, %UserTitle{} = user_title} = Media.mark_as_watched(user.id, title.id, attrs)
      assert user_title.status == :watched
      assert user_title.rating == 9
      assert user_title.date_watched == ~D[2023-01-15]
    end

    test "mark_as_watching/3 creates watching user_title" do
      user = user_fixture()
      title = title_fixture()
      attrs = %{episodes_watched: 5, total_episodes: 10, notes: "Great show!"}

      assert {:ok, %UserTitle{} = user_title} = Media.mark_as_watching(user.id, title.id, attrs)
      assert user_title.status == :watching
      assert user_title.episodes_watched == 5
      assert user_title.total_episodes == 10
    end

    test "mark_as_want_to_watch/3 creates want_to_watch user_title" do
      user = user_fixture()
      title = title_fixture()
      attrs = %{notes: "Want to watch this!"}

      assert {:ok, %UserTitle{} = user_title} =
               Media.mark_as_want_to_watch(user.id, title.id, attrs)

      assert user_title.status == :want_to_watch
      assert user_title.notes == "Want to watch this!"
    end

    test "mark_as_favorite/3 creates favorite user_title" do
      user = user_fixture()
      title = title_fixture()
      attrs = %{notes: "One of my favorites!"}

      assert {:ok, %UserTitle{} = user_title} = Media.mark_as_favorite(user.id, title.id, attrs)
      assert user_title.status == :favorite
      assert user_title.notes == "One of my favorites!"
    end

    test "get_user_titles/1 returns user's titles" do
      user = user_fixture()
      user_title = user_title_fixture(%{user_id: user.id})
      assert [fetched_user_title] = Media.get_user_titles(user.id)
      assert fetched_user_title.id == user_title.id
    end

    test "get_user_titles_by_status/2 returns user's titles by status" do
      user = user_fixture()
      user_title = user_title_fixture(%{user_id: user.id, status: :watching})
      assert [fetched_user_title] = Media.get_user_titles_by_status(user.id, :watching)
      assert fetched_user_title.id == user_title.id
    end

    test "get_watched_titles/1 returns user's watched titles" do
      user = user_fixture()
      user_title = user_title_fixture(%{user_id: user.id, status: :watched})
      assert [fetched_user_title] = Media.get_watched_titles(user.id)
      assert fetched_user_title.id == user_title.id
    end

    test "get_watching_titles/1 returns user's watching titles" do
      user = user_fixture()
      user_title = user_title_fixture(%{user_id: user.id, status: :watching})
      assert [fetched_user_title] = Media.get_watching_titles(user.id)
      assert fetched_user_title.id == user_title.id
    end

    test "get_want_to_watch_titles/1 returns user's want to watch titles" do
      user = user_fixture()
      user_title = user_title_fixture(%{user_id: user.id, status: :want_to_watch})
      assert [fetched_user_title] = Media.get_want_to_watch_titles(user.id)
      assert fetched_user_title.id == user_title.id
    end

    test "get_favorite_titles/1 returns user's favorite titles" do
      user = user_fixture()
      user_title = user_title_fixture(%{user_id: user.id, status: :favorite})
      assert [fetched_user_title] = Media.get_favorite_titles(user.id)
      assert fetched_user_title.id == user_title.id
    end

    test "delete_user_title/1 deletes the user_title" do
      user_title = user_title_fixture()
      assert {:ok, %UserTitle{}} = Media.delete_user_title(user_title)
      assert Media.get_user_title(user_title.user_id, user_title.title_id) == nil
    end

    test "delete_user_title/2 deletes user_title by user_id and title_id" do
      user_title = user_title_fixture()

      assert {:ok, %UserTitle{}} =
               Media.delete_user_title(user_title.user_id, user_title.title_id)

      assert Media.get_user_title(user_title.user_id, user_title.title_id) == nil
    end

    test "delete_user_title/2 returns error for non-existent user_title" do
      user = user_fixture()
      title = title_fixture()
      assert {:error, :not_found} = Media.delete_user_title(user.id, title.id)
    end
  end

  test "calculate_actual_time_spent with real data" do
    # Create a user
    user = Javi.AccountsFixtures.user_fixture()

    # Create a watched list for the user
    {:ok, watched_list} =
      Javi.Accounts.create_list(user, %{
        name: "Assistidos",
        description: "Filmes e séries assistidos",
        list_type: "watched"
      })

    # Create a title with duration data
    {:ok, title} =
      Media.create_title(%{
        tmdb_id: 123,
        tmdb_type: "movie",
        title: "Test Movie",
        runtime: 120,
        episode_run_time: nil,
        number_of_seasons: nil,
        number_of_episodes: nil
      })

    # Add title to watched list
    {:ok, _list_item} = Javi.Accounts.add_title_to_list(watched_list, title)

    # Calculate time spent
    minutes = Media.calculate_actual_time_spent(user.id)

    # Should be 120 minutes (2 hours)
    assert minutes == 120

    # Test with TV show
    {:ok, tv_title} =
      Media.create_title(%{
        tmdb_id: 456,
        tmdb_type: "tv",
        title: "Test TV Show",
        runtime: nil,
        episode_run_time: [45],
        number_of_seasons: 1,
        number_of_episodes: 2
      })

    # Add TV show to watched list
    {:ok, _tv_list_item} = Javi.Accounts.add_title_to_list(watched_list, tv_title)

    # Calculate time spent again
    total_minutes = Media.calculate_actual_time_spent(user.id)

    # Should be 120 + 90 = 210 minutes
    assert total_minutes == 210
  end
end
