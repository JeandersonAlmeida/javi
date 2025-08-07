defmodule Javi.Accounts.UserTokenTest do
  use Javi.DataCase

  alias Javi.Accounts.{UserToken}
  alias Javi.Repo

  import Javi.AccountsFixtures

  describe "build_session_token/1" do
    test "builds a session token" do
      user = user_fixture()
      {token, user_token} = UserToken.build_session_token(user)

      assert is_binary(token)
      assert user_token.context == "session"
      assert user_token.user_id == user.id
      assert is_binary(user_token.token)
    end
  end

  describe "verify_session_token_query/1" do
    test "returns valid query for session token" do
      user = user_fixture()
      {token, user_token} = UserToken.build_session_token(user)
      Repo.insert!(user_token)

      assert {:ok, query} = UserToken.verify_session_token_query(token)
      assert Repo.one(query).id == user.id
    end

    test "returns error for invalid token" do
      assert {:ok, query} = UserToken.verify_session_token_query("invalid_token")
      assert Repo.one(query) == nil
    end
  end

  describe "build_email_token/2" do
    test "builds an email token" do
      user = user_fixture()
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")

      assert is_binary(encoded_token)
      assert user_token.context == "confirm"
      assert user_token.sent_to == user.email
      assert user_token.user_id == user.id
      assert is_binary(user_token.token)
    end
  end

  describe "verify_email_token_query/2" do
    test "returns valid query for email token" do
      user = user_fixture()
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)

      assert {:ok, query} = UserToken.verify_email_token_query(encoded_token, "confirm")
      assert Repo.one(query).id == user.id
    end

    test "returns error for invalid token" do
      # Use a valid base64 token that doesn't exist in database
      valid_base64 = Base.url_encode64("invalid_token", padding: false)
      assert {:ok, query} = UserToken.verify_email_token_query(valid_base64, "confirm")
      assert Repo.one(query) == nil
    end

    test "returns error for malformed token" do
      assert :error = UserToken.verify_email_token_query("invalid_base64", "confirm")
    end

    test "handles reset_password context" do
      user = user_fixture()
      {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
      Repo.insert!(user_token)

      assert {:ok, query} = UserToken.verify_email_token_query(encoded_token, "reset_password")
      assert Repo.one(query).id == user.id
    end
  end

  describe "verify_change_email_token_query/2" do
    test "returns valid query for change email token" do
      user = user_fixture()
      {encoded_token, user_token} = UserToken.build_email_token(user, "change:old@example.com")
      Repo.insert!(user_token)

      assert {:ok, query} =
               UserToken.verify_change_email_token_query(encoded_token, "change:old@example.com")

      assert Repo.one(query).id == user_token.id
    end

    test "returns error for invalid context" do
      assert :error = UserToken.verify_change_email_token_query("token", "invalid_context")
    end

    test "returns error for malformed token" do
      # Use a valid base64 token that doesn't exist in database
      valid_base64 = Base.url_encode64("invalid_token", padding: false)

      assert {:ok, query} =
               UserToken.verify_change_email_token_query(valid_base64, "change:old@example.com")

      assert Repo.one(query) == nil
    end
  end

  describe "by_token_and_context_query/2" do
    test "returns query for token and context" do
      user = user_fixture()
      {token, user_token} = UserToken.build_session_token(user)
      Repo.insert!(user_token)

      query = UserToken.by_token_and_context_query(token, "session")
      found_token = Repo.one(query)

      assert found_token.id == user_token.id
      assert found_token.context == "session"
    end

    test "returns nil for non-existent token" do
      query = UserToken.by_token_and_context_query("non_existent_token", "session")
      assert Repo.one(query) == nil
    end
  end

  describe "by_user_and_contexts_query/2" do
    test "returns query for user and all contexts" do
      user = user_fixture()
      {_token1, user_token1} = UserToken.build_session_token(user)
      {_token2, user_token2} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token1)
      Repo.insert!(user_token2)

      query = UserToken.by_user_and_contexts_query(user, :all)
      tokens = Repo.all(query)

      assert length(tokens) == 2
      assert Enum.any?(tokens, &(&1.context == "session"))
      assert Enum.any?(tokens, &(&1.context == "confirm"))
    end

    test "returns query for user and specific contexts" do
      user = user_fixture()
      {_token1, user_token1} = UserToken.build_session_token(user)
      {_token2, user_token2} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token1)
      Repo.insert!(user_token2)

      query = UserToken.by_user_and_contexts_query(user, ["session"])
      tokens = Repo.all(query)

      assert length(tokens) == 1
      assert hd(tokens).context == "session"
    end
  end

  describe "token expiration" do
    test "session token expires after validity period" do
      user = user_fixture()
      {token, user_token} = UserToken.build_session_token(user)

      # Set the token to be older than the validity period
      old_date = DateTime.utc_now() |> DateTime.add(-61, :day) |> DateTime.truncate(:second)
      user_token = %{user_token | inserted_at: old_date}
      Repo.insert!(user_token)

      assert {:ok, query} = UserToken.verify_session_token_query(token)
      assert Repo.one(query) == nil
    end

    test "email token expires after validity period" do
      user = user_fixture()
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")

      # Set the token to be older than the validity period
      old_date = DateTime.utc_now() |> DateTime.add(-8, :day) |> DateTime.truncate(:second)
      user_token = %{user_token | inserted_at: old_date}
      Repo.insert!(user_token)

      assert {:ok, query} = UserToken.verify_email_token_query(encoded_token, "confirm")
      assert Repo.one(query) == nil
    end

    test "reset password token expires after validity period" do
      user = user_fixture()
      {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")

      # Set the token to be older than the validity period
      old_date = DateTime.utc_now() |> DateTime.add(-2, :day) |> DateTime.truncate(:second)
      user_token = %{user_token | inserted_at: old_date}
      Repo.insert!(user_token)

      assert {:ok, query} = UserToken.verify_email_token_query(encoded_token, "reset_password")
      assert Repo.one(query) == nil
    end
  end

  describe "token uniqueness" do
    test "session tokens are unique per user" do
      user = user_fixture()
      {_token1, user_token1} = UserToken.build_session_token(user)
      {_token2, user_token2} = UserToken.build_session_token(user)
      Repo.insert!(user_token1)

      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(user_token2)
      end
    end
  end

  describe "email change validation" do
    test "email token validation fails when email changes" do
      user = user_fixture()
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)

      # Change user email
      {:ok, _updated_user} = Javi.Accounts.update_user(user, %{email: "new@example.com"})

      # Token should no longer be valid
      assert {:ok, query} = UserToken.verify_email_token_query(encoded_token, "confirm")
      assert Repo.one(query) == nil
    end
  end
end
