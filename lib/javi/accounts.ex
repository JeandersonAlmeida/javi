defmodule Javi.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Javi.Repo

  alias Javi.Accounts.{User, UserToken, UserNotifier, List, ListItem, StaffUser, StaffUserToken}

  ## Database getters

  @doc """
  Gets a user by email.

  Normalizes by trimming and downcasing.
  """
  def get_user_by_email(email) when is_binary(email) do
    email = email |> String.trim() |> String.downcase()
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets all users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Lists users with aggregated stats for Ops dashboard:
  - list_count: distinct count of lists per user
  - last_title_added_at: latest added_at across all user's list items
  Ordered by newest users and limited to the given amount (default: 20).
  """
  def list_users_with_stats(limit \\ 20) when is_integer(limit) and limit > 0 do
    from(u in User,
      left_join: l in List,
      on: l.user_id == u.id,
      left_join: li in ListItem,
      on: li.list_id == l.id,
      group_by: u.id,
      order_by: [desc: u.inserted_at],
      select: u,
      select_merge: %{
        list_count: count(l.id, :distinct),
        last_title_added_at: max(li.added_at)
      },
      limit: ^limit
    )
    |> Repo.all()
  end

  # ---------- Staff Helpers ----------

  defp normalize_email(email) when is_binary(email),
    do: email |> String.trim() |> String.downcase()

  defp normalize_email(email), do: email

  @doc """
  Gets a staff user by email (normalized).
  """
  def get_staff_user_by_email(email) when is_binary(email) do
    Repo.get_by(StaffUser, email: normalize_email(email))
  end

  @doc """
  Gets a staff user by email and password.
  Trims input and performs case-insensitive email lookup (citext) with normalized string.
  """
  def get_staff_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    staff = Repo.get_by(StaffUser, email: normalize_email(email))

    if staff && StaffUser.valid_password?(staff, String.trim(password)) do
      staff
    else
      nil
    end
  end

  ## Staff users (Ops)

  @doc """
  Registers a staff user.
  """
  def register_staff_user(attrs \\ %{}) do
    %StaffUser{}
    |> StaffUser.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists staff users.
  """
  def list_staff_users do
    Repo.all(StaffUser)
  end

  @doc """
  Generates a staff session token.
  """
  def generate_staff_user_session_token(staff) do
    {token, staff_token} = StaffUserToken.build_session_token(staff)
    Repo.insert!(staff_token)
    token
  end

  @doc """
  Gets the staff user from a session token.
  """
  def get_staff_user_by_session_token(token) do
    {:ok, query} = StaffUserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes a staff session token by raw token.
  """
  def delete_staff_user_session_token(token) do
    Repo.delete_all(StaffUserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs \\ %{}) do
    attrs = ensure_generated_nickname(attrs)

    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        # Create default lists for the new user (synchronous inserts)
        User.create_default_lists(user)

        # Broadcast to Ops Dashboard subscribers so it updates in real-time
        Phoenix.PubSub.broadcast(Javi.PubSub, "accounts:users", {:user_created, user.id})

        {:ok, user}

      error ->
        error
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates user activity statistics.

  ## Examples

      iex> update_user_activity(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user_activity(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_activity(%User{} = user, attrs) do
    user
    |> User.activity_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Updates the user password without current password validation.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, %{password: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user profile.

  ## Examples

      iex> change_user_profile(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_profile(user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  @doc """
  Updates the user profile.

  ## Examples

      iex> update_user_profile(user, %{display_name: "John Doe"})
      {:ok, %User{}}

      iex> update_user_profile(user, %{display_name: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_profile(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates user privacy settings.

  ## Examples

      iex> update_user_privacy_settings(user, %{public_profile: true})
      {:ok, %User{}}

      iex> update_user_privacy_settings(user, %{public_profile: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_privacy_settings(user, attrs) do
    user
    |> User.privacy_settings_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates user social settings.

  ## Examples

      iex> update_user_social_settings(user, %{follower_notifications: true})
      {:ok, %User{}}

      iex> update_user_social_settings(user, %{follower_notifications: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_social_settings(user, attrs) do
    user
    |> User.social_settings_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Removes user photo.

  ## Examples

      iex> remove_user_photo(user)
      {:ok, %User{}}

      iex> remove_user_photo(user)
      {:error, %Ecto.Changeset{}}

  """
  def remove_user_photo(user) do
    user
    |> User.photo_changeset(%{photo_url: nil})
    |> Repo.update()
  end

  @doc """
  Applies user email without password validation.

  ## Examples

      iex> apply_user_email(user, %{email: "new@example.com"})
      {:ok, %User{}}

      iex> apply_user_email(user, %{email: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, attrs) do
    user
    |> User.email_changeset(attrs)
    |> Ecto.Changeset.apply_action(:update)
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  ## Lists

  @doc """
  Gets all lists for a user.

  ## Examples

      iex> get_user_lists(user)
      [%List{}, ...]

  """
  def get_user_lists(%User{} = user) do
    List
    |> where([l], l.user_id == ^user.id)
    |> order_by([l], desc: l.inserted_at)
    |> preload(list_items: :title)
    |> Repo.all()
  end

  @doc """
  Gets a single list by ID for a user.

  ## Examples

      iex> get_user_list(user, 123)
      %List{}

      iex> get_user_list(user, 456)
      nil

  """
  def get_user_list(%User{} = user, list_id) do
    List
    |> where([l], l.id == ^list_id and l.user_id == ^user.id)
    |> preload(list_items: :title)
    |> Repo.one()
  end

  @doc """
  Creates a new list for a user.

  ## Examples

      iex> create_list(user, %{name: "My Favorites"})
      {:ok, %List{}}

      iex> create_list(user, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_list(%User{} = user, attrs) do
    %List{}
    |> List.create_changeset(Map.put(attrs, :user_id, user.id))
    |> Repo.insert()
  end

  @doc """
  Updates a list.

  ## Examples

      iex> update_list(list, %{name: "Updated Name"})
      {:ok, %List{}}

      iex> update_list(list, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def update_list(%List{} = list, attrs) do
    list
    |> List.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a list.

  ## Examples

      iex> delete_list(list)
      {:ok, %List{}}

      iex> delete_list(list)
      {:error, %Ecto.Changeset{}}

  """
  def delete_list(%List{} = list) do
    Repo.delete(list)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking list changes.

  ## Examples

      iex> change_list(list)
      %Ecto.Changeset{data: %List{}}

  """
  def change_list(%List{} = list, attrs \\ %{}) do
    List.changeset(list, attrs)
  end

  ## List Items

  @doc """
  Gets all items in a list.

  ## Examples

      iex> get_list_items(list)
      [%ListItem{}, ...]

  """
  def get_list_items(%List{} = list) do
    ListItem
    |> where([li], li.list_id == ^list.id)
    |> order_by([li], asc: li.position)
    |> preload(:title)
    |> Repo.all()
  end

  @doc """
  Adds a title to a list.

  ## Examples

      iex> add_title_to_list(list, title)
      {:ok, %ListItem{}}

      iex> add_title_to_list(list, title)
      {:error, %Ecto.Changeset{}}

  """
  def add_title_to_list(%List{} = list, %Javi.Media.Title{} = title) do
    # Get the next position
    max_position =
      ListItem
      |> where([li], li.list_id == ^list.id)
      |> select([li], coalesce(max(li.position), 0))
      |> Repo.one()

    result =
      %ListItem{}
      |> ListItem.create_changeset(%{
        list_id: list.id,
        title_id: title.id,
        position: max_position + 1
      })
      |> Repo.insert()

    # Broadcast stats update if this is a watched list
    case result do
      {:ok, _list_item} ->
        if list.list_type == "watched" do
          Phoenix.PubSub.broadcast(
            Javi.PubSub,
            "user_stats:#{list.user_id}",
            {:stats_updated, list.user_id}
          )
        end

      _ ->
        :ok
    end

    result
  end

  @doc """
  Removes a title from a list.

  ## Examples

      iex> remove_title_from_list(list, title)
      {:ok, %ListItem{}}

      iex> remove_title_from_list(list, title)
      {:error, :not_found}

  """
  def remove_title_from_list(%List{} = list, %Javi.Media.Title{} = title) do
    case Repo.get_by(ListItem, list_id: list.id, title_id: title.id) do
      nil -> {:error, :not_found}
      list_item -> Repo.delete(list_item)
    end
  end

  def remove_title_from_list(%List{} = list, list_item_id) when is_integer(list_item_id) do
    case Repo.get_by(ListItem, id: list_item_id, list_id: list.id) do
      nil ->
        {:error, :not_found}

      list_item ->
        result = Repo.delete(list_item)

        # Broadcast stats update if this is a watched list
        case result do
          {:ok, _deleted_item} ->
            if list.list_type == "watched" do
              Phoenix.PubSub.broadcast(
                Javi.PubSub,
                "user_stats:#{list.user_id}",
                {:stats_updated, list.user_id}
              )
            end

          _ ->
            :ok
        end

        result
    end
  end

  @doc """
  Updates a list item.

  ## Examples

      iex> update_list_item(list_item, %{notes: "Great movie!"})
      {:ok, %ListItem{}}

      iex> update_list_item(list_item, %{notes: ""})
      {:error, %Ecto.Changeset{}}

  """
  def update_list_item(%ListItem{} = list_item, attrs) do
    list_item
    |> ListItem.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Gets a user's watched list.
  """
  def get_user_watched_list(%User{} = user) do
    List
    |> where([l], l.user_id == ^user.id and l.list_type == "watched")
    |> preload(list_items: :title)
    |> Repo.all()
    |> case do
      [] -> nil
      [first | _] -> first
    end
  end

  # --- Nickname helpers (Accounts) ---

  # Ensures we generate a nickname during registration if none was supplied.
  # Keeps attrs structure (string keys typical from forms).
  defp ensure_generated_nickname(attrs) when is_map(attrs) do
    provided =
      Map.get(attrs, "nickname") ||
        Map.get(attrs, :nickname)

    if present?(provided) do
      # Leave provided nickname as-is; schema validations will normalize/validate/unique it.
      attrs
    else
      display_name = Map.get(attrs, "display_name") || Map.get(attrs, :display_name)
      email = Map.get(attrs, "email") || Map.get(attrs, :email)

      base =
        cond do
          is_binary(display_name) and String.trim(display_name) != "" ->
            display_name

          is_binary(email) and String.trim(email) != "" ->
            email |> String.split("@") |> List.first()

          true ->
            "user"
        end

      normalized = normalize_nickname(base)

      nickname = generate_unique_nickname(normalized)

      # Use string key to match LiveView form params
      Map.put(attrs, "nickname", nickname)
    end
  end

  def nickname_available?(nickname, exclude_user_id \\ nil) do
    normalized = normalize_nickname(nickname || "")

    cond do
      normalized == "" ->
        false

      true ->
        case Repo.get_by(User, nickname: normalized) do
          nil -> true
          %User{id: id} when not is_nil(exclude_user_id) and id == exclude_user_id -> true
          _ -> false
        end
    end
  end

  def generate_unique_nickname(base) do
    base =
      base
      |> normalize_nickname()
      |> case do
        "" -> "user"
        other -> other
      end

    # Try base, then base-2, base-3, ...
    if Repo.get_by(User, nickname: base) == nil do
      base
    else
      Stream.iterate(2, &(&1 + 1))
      |> Enum.reduce_while(nil, fn n, _acc ->
        candidate = "#{base}-#{n}"

        if Repo.get_by(User, nickname: candidate) == nil do
          {:halt, candidate}
        else
          {:cont, nil}
        end
      end)
      |> case do
        nil -> base <> "-#{System.unique_integer([:positive])}"
        candidate -> candidate
      end
    end
  end

  defp normalize_nickname(nickname) when is_binary(nickname) do
    nickname
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9._-]+/u, "-")
    |> String.replace(~r/[-_.]{2,}/, "-")
    |> String.trim("-._")
  end

  defp normalize_nickname(_), do: ""

  defp present?(val) when is_binary(val), do: String.trim(val) != ""
  defp present?(_), do: false
end
