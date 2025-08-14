defmodule Javi.Accounts.FriendsTest do
  use Javi.DataCase, async: true

  alias Javi.Accounts
  import Javi.AccountsFixtures

  test "send friend request validates self and duplicates" do
    sender = user_fixture()
    recipient = user_fixture()

    assert {:ok, _} = Accounts.send_friend_request(sender, recipient)
    assert {:error, _} = Accounts.send_friend_request(sender, recipient)
    assert {:error, :cannot_self_request} = Accounts.send_friend_request(sender, sender)
  end

  test "accept and create friendship" do
    a = user_fixture()
    b = user_fixture()

    {:ok, req} = Accounts.send_friend_request(a, b)
    assert {:ok, _friendship} = Accounts.accept_friend_request(b, req.id)

    assert Accounts.friends?(a, b)
    assert Accounts.friend_count(a) == 1
    assert Accounts.friend_count(b) == 1
  end

  test "decline request removes it" do
    a = user_fixture()
    b = user_fixture()

    {:ok, req} = Accounts.send_friend_request(a, b)
    assert {:ok, :deleted} = Accounts.decline_friend_request(b, req.id)

    assert Accounts.list_incoming_friend_requests(b) == []
  end

  test "remove friend" do
    a = user_fixture()
    b = user_fixture()

    {:ok, req} = Accounts.send_friend_request(a, b)
    {:ok, _} = Accounts.accept_friend_request(b, req.id)

    assert {:ok, :deleted} = Accounts.remove_friend(a, b)
    refute Accounts.friends?(a, b)
  end
end
