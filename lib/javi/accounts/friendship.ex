defmodule Javi.Accounts.Friendship do
  use Ecto.Schema
  import Ecto.Changeset

  schema "friendships" do
    belongs_to :user, Javi.Accounts.User
    belongs_to :friend, Javi.Accounts.User

    timestamps()
  end

  @doc """
  Creates a friendship between two users. Enforces canonical order (lower id first).
  """
  def create_changeset(friendship, attrs) do
    {user_id, friend_id} =
      canonical_pair(attrs[:user_id] || attrs["user_id"], attrs[:friend_id] || attrs["friend_id"])

    friendship
    |> cast(%{user_id: user_id, friend_id: friend_id}, [:user_id, :friend_id])
    |> validate_required([:user_id, :friend_id])
    |> validate_number(:user_id, greater_than: 0)
    |> validate_number(:friend_id, greater_than: 0)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:friend_id)
    |> unique_constraint([:user_id, :friend_id], name: :unique_friend_pair)
    |> check_constraint(:user_id, name: :friendships_canonical_order)
    |> check_constraint(:user_id, name: :friendships_no_self)
  end

  defp canonical_pair(a, b) when is_integer(a) and is_integer(b) do
    if a < b, do: {a, b}, else: {b, a}
  end

  defp canonical_pair(a, b) do
    {to_int(a), to_int(b)} |> then(fn {x, y} -> if x < y, do: {x, y}, else: {y, x} end)
  end

  defp to_int(nil), do: 0

  defp to_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {i, _} -> i
      _ -> 0
    end
  end

  defp to_int(v) when is_integer(v), do: v
end
