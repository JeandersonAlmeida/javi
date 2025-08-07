defmodule Javi.Accounts.UserTest do
  use Javi.DataCase

  alias Javi.Accounts.User
  alias Javi.Repo

  import Javi.AccountsFixtures

  describe "changesets" do
    test "registration_changeset/2 with valid attributes" do
      attrs = %{
        email: "test@example.com",
        password: "valid_password",
        display_name: "Test User"
      }

      changeset = User.registration_changeset(%User{}, attrs)
      assert changeset.valid?
    end

    test "registration_changeset/2 with invalid email" do
      attrs = %{
        email: "invalid-email",
        password: "valid_password",
        display_name: "Test User"
      }

      changeset = User.registration_changeset(%User{}, attrs)
      refute changeset.valid?
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end

    test "registration_changeset/2 with short password" do
      attrs = %{
        email: "test@example.com",
        password: "short",
        display_name: "Test User"
      }

      changeset = User.registration_changeset(%User{}, attrs)
      refute changeset.valid?
      assert "should be at least 6 character(s)" in errors_on(changeset).password
    end

    test "registration_changeset/2 with invalid display_name" do
      attrs = %{
        email: "test@example.com",
        password: "valid_password",
        display_name: "123"
      }

      changeset = User.registration_changeset(%User{}, attrs)
      refute changeset.valid?
      assert "must contain only letters and spaces" in errors_on(changeset).display_name
    end

    test "email_changeset/2 with valid email" do
      user = user_fixture()
      attrs = %{email: "new@example.com"}
      changeset = User.email_changeset(user, attrs)
      assert changeset.valid?
    end

    test "email_changeset/2 with same email" do
      user = user_fixture()
      attrs = %{email: user.email}
      changeset = User.email_changeset(user, attrs)
      refute changeset.valid?
      assert "did not change" in errors_on(changeset).email
    end

    test "password_changeset/2 with valid password" do
      user = user_fixture()
      attrs = %{password: "new_password", password_confirmation: "new_password"}
      changeset = User.password_changeset(user, attrs)
      assert changeset.valid?
    end

    test "password_changeset/2 with mismatched confirmation" do
      user = user_fixture()
      attrs = %{password: "new_password", password_confirmation: "different"}
      changeset = User.password_changeset(user, attrs)
      refute changeset.valid?
      assert "does not match password" in errors_on(changeset).password_confirmation
    end

    test "confirm_changeset/1 sets confirmed_at" do
      user = user_fixture()
      changeset = User.confirm_changeset(user)
      assert get_change(changeset, :confirmed_at)
    end

    test "profile_changeset/2 with valid attributes" do
      user = user_fixture()

      attrs = %{
        display_name: "John Doe",
        bio: "Movie enthusiast",
        preferred_language: "en-US",
        rating_scale: 5
      }

      changeset = User.profile_changeset(user, attrs)
      assert changeset.valid?
    end

    test "profile_changeset/2 with invalid rating_scale" do
      user = user_fixture()
      attrs = %{rating_scale: 7}
      changeset = User.profile_changeset(user, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).rating_scale
    end

    test "privacy_settings_changeset/2 with valid attributes" do
      user = user_fixture()
      attrs = %{public_profile: false, show_activity: false}
      changeset = User.privacy_settings_changeset(user, attrs)
      assert changeset.valid?
    end

    test "social_settings_changeset/2 with valid attributes" do
      user = user_fixture()
      attrs = %{follower_notifications: false, share_lists: false}
      changeset = User.social_settings_changeset(user, attrs)
      assert changeset.valid?
    end

    test "photo_changeset/2 with valid URL" do
      user = user_fixture()
      attrs = %{photo_url: "https://example.com/photo.jpg"}
      changeset = User.photo_changeset(user, attrs)
      assert changeset.valid?
    end

    test "photo_changeset/2 with invalid URL" do
      user = user_fixture()
      attrs = %{photo_url: "not-a-url"}
      changeset = User.photo_changeset(user, attrs)
      refute changeset.valid?
      assert "must be a valid URL" in errors_on(changeset).photo_url
    end

    test "notification_changeset/2 with valid attributes" do
      user = user_fixture()
      attrs = %{email_notifications: false, weekly_digest: false}
      changeset = User.notification_changeset(user, attrs)
      assert changeset.valid?
    end

    test "content_preferences_changeset/2 with valid attributes" do
      user = user_fixture()

      attrs = %{
        preferred_genres: ["Action", "Drama"],
        excluded_genres: ["Horror"],
        min_rating_filter: 5
      }

      changeset = User.content_preferences_changeset(user, attrs)
      assert changeset.valid?
    end

    test "content_preferences_changeset/2 with invalid min_rating_filter" do
      user = user_fixture()
      attrs = %{min_rating_filter: 15}
      changeset = User.content_preferences_changeset(user, attrs)
      refute changeset.valid?
      assert "must be less than or equal to 10" in errors_on(changeset).min_rating_filter
    end

    test "activity_changeset/2 with valid attributes" do
      user = user_fixture()

      attrs = %{
        total_watched: 10,
        total_watching: 5,
        average_rating: Decimal.new("8.5")
      }

      changeset = User.activity_changeset(user, attrs)
      assert changeset.valid?
    end

    test "activity_changeset/2 with invalid negative values" do
      user = user_fixture()
      attrs = %{total_watched: -1}
      changeset = User.activity_changeset(user, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).total_watched
    end

    test "soft_delete_changeset/1 sets deleted status" do
      user = user_fixture()
      changeset = User.soft_delete_changeset(user)
      assert get_change(changeset, :account_status) == "deleted"
      assert get_change(changeset, :deleted_at)
    end

    test "reactivate_changeset/1 reactivates account" do
      user = %{user_fixture() | account_status: "deleted", deleted_at: DateTime.utc_now()}
      changeset = User.reactivate_changeset(user)
      assert get_change(changeset, :account_status) == "active"
      assert get_change(changeset, :deleted_at) == nil
    end

    test "update_activity_changeset/1 updates activity timestamp" do
      user = user_fixture()
      changeset = User.update_activity_changeset(user)
      assert get_change(changeset, :last_activity_at)
    end

    test "complete_onboarding_changeset/1 marks onboarding as completed" do
      user = user_fixture()
      changeset = User.complete_onboarding_changeset(user)
      assert get_change(changeset, :onboarding_completed) == true
    end
  end

  describe "password validation" do
    test "valid_password?/2 with correct password" do
      user = user_fixture()
      assert User.valid_password?(user, valid_user_password())
    end

    test "valid_password?/2 with incorrect password" do
      user = user_fixture()
      refute User.valid_password?(user, "wrong_password")
    end

    test "valid_password?/2 with nil user" do
      refute User.valid_password?(nil, "password")
    end

    test "valid_password?/2 with user without hashed_password" do
      user = %{user_fixture() | hashed_password: nil}
      refute User.valid_password?(user, "password")
    end

    test "validate_current_password/2 with valid password" do
      user = user_fixture()

      changeset =
        User.validate_current_password(
          %Ecto.Changeset{data: user, changes: %{}, errors: [], valid?: true},
          valid_user_password()
        )

      assert changeset.valid?
    end

    test "validate_current_password/2 with invalid password" do
      user = user_fixture()

      changeset =
        User.validate_current_password(
          %Ecto.Changeset{data: user, changes: %{}, errors: [], valid?: true},
          "wrong_password"
        )

      refute changeset.valid?
      assert "is not valid" in errors_on(changeset).current_password
    end
  end

  describe "genre validation" do
    test "validate_preferred_genres with valid list" do
      user = user_fixture()
      attrs = %{preferred_genres: ["Action", "Drama"]}
      changeset = User.profile_changeset(user, attrs)
      assert changeset.valid?
    end

    test "validate_preferred_genres with invalid list" do
      user = user_fixture()
      attrs = %{preferred_genres: ["Action", 123]}
      changeset = User.profile_changeset(user, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).preferred_genres
    end

    test "validate_excluded_genres with valid list" do
      user = user_fixture()
      attrs = %{excluded_genres: ["Horror", "Thriller"]}
      changeset = User.profile_changeset(user, attrs)
      assert changeset.valid?
    end

    test "validate_excluded_genres with invalid list" do
      user = user_fixture()
      attrs = %{excluded_genres: ["Horror", 456]}
      changeset = User.profile_changeset(user, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).excluded_genres
    end
  end

  describe "default lists" do
    test "create_default_lists/1 creates default lists" do
      user = user_fixture()
      User.create_default_lists(user)

      lists = Javi.Accounts.get_user_lists(user)
      list_types = Enum.map(lists, & &1.list_type)

      assert "watched" in list_types
      assert "watching" in list_types
      assert "favorites" in list_types
    end

    test "get_default_lists/1 returns default lists" do
      user = user_fixture()

      default_lists = User.get_default_lists(user)
      assert length(default_lists) >= 3

      list_types = Enum.map(default_lists, & &1.list_type)
      assert "watched" in list_types
      assert "watching" in list_types
      assert "favorites" in list_types
    end
  end

  describe "inspect" do
    test "inspect/2 does not include password" do
      user = %{user_fixture() | password: "secret_password"}
      user_string = inspect(user)
      refute user_string =~ "secret_password"
    end
  end

  describe "additional changeset functions" do
    test "privacy_changeset/2 with valid attributes" do
      user = user_fixture()
      attrs = %{profile_visibility: "private", show_ratings: false}
      changeset = User.privacy_changeset(user, attrs)
      assert changeset.valid?
    end

    test "privacy_changeset/2 with invalid profile_visibility" do
      user = user_fixture()
      attrs = %{profile_visibility: "invalid"}
      changeset = User.privacy_changeset(user, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).profile_visibility
    end

    test "notification_changeset/2 with valid attributes" do
      user = user_fixture()
      attrs = %{email_notifications: false, weekly_digest: false}
      changeset = User.notification_changeset(user, attrs)
      assert changeset.valid?
    end

    test "content_preferences_changeset/2 with valid attributes" do
      user = user_fixture()

      attrs = %{
        preferred_genres: ["Action", "Drama"],
        excluded_genres: ["Horror"],
        min_rating_filter: 5
      }

      changeset = User.content_preferences_changeset(user, attrs)
      assert changeset.valid?
    end

    test "content_preferences_changeset/2 with invalid min_rating_filter" do
      user = user_fixture()
      attrs = %{min_rating_filter: 15}
      changeset = User.content_preferences_changeset(user, attrs)
      refute changeset.valid?
      assert "must be less than or equal to 10" in errors_on(changeset).min_rating_filter
    end

    test "activity_changeset/2 with valid attributes" do
      user = user_fixture()

      attrs = %{
        total_watched: 10,
        total_watching: 5,
        average_rating: Decimal.new("8.5")
      }

      changeset = User.activity_changeset(user, attrs)
      assert changeset.valid?
    end

    test "activity_changeset/2 with invalid negative values" do
      user = user_fixture()
      attrs = %{total_watched: -1}
      changeset = User.activity_changeset(user, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).total_watched
    end

    test "activity_changeset/2 with invalid average_rating" do
      user = user_fixture()
      attrs = %{average_rating: Decimal.new("11.0")}
      changeset = User.activity_changeset(user, attrs)
      refute changeset.valid?
      assert "must be less than or equal to 10" in errors_on(changeset).average_rating
    end
  end

  describe "registration changeset options" do
    test "registration_changeset/2 with hash_password: false" do
      attrs = %{
        email: "test@example.com",
        password: "valid_password",
        display_name: "Test User"
      }

      changeset = User.registration_changeset(%User{}, attrs, hash_password: false)
      assert changeset.valid?
      assert get_change(changeset, :password) == "valid_password"
      assert get_change(changeset, :hashed_password) == nil
    end

    test "registration_changeset/2 with validate_email: false" do
      attrs = %{
        email: "test@example.com",
        password: "valid_password",
        display_name: "Test User"
      }

      changeset = User.registration_changeset(%User{}, attrs, validate_email: false)
      assert changeset.valid?
    end

    test "change_user_registration/2 returns changeset" do
      user = user_fixture()
      changeset = Javi.Accounts.change_user_registration(user)
      assert %Ecto.Changeset{} = changeset
      assert changeset.data == user
    end

    test "change_user_registration/2 with attrs" do
      user = user_fixture()
      attrs = %{email: "new@example.com"}
      changeset = Javi.Accounts.change_user_registration(user, attrs)
      assert %Ecto.Changeset{} = changeset
      assert get_change(changeset, :email) == "new@example.com"
    end
  end

  describe "password changeset options" do
    test "password_changeset/2 with hash_password: false" do
      user = user_fixture()
      attrs = %{password: "new_password", password_confirmation: "new_password"}
      changeset = User.password_changeset(user, attrs, hash_password: false)
      assert changeset.valid?
      assert get_change(changeset, :password) == "new_password"
      assert get_change(changeset, :hashed_password) == nil
    end
  end

  describe "email changeset options" do
    test "email_changeset/2 with validate_email: false" do
      user = user_fixture()
      attrs = %{email: "new@example.com"}
      changeset = User.email_changeset(user, attrs, validate_email: false)
      assert changeset.valid?
    end
  end
end
