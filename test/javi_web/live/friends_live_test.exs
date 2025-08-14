defmodule JaviWeb.FriendsLiveTest do
  use JaviWeb.ConnCase

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures

  alias Javi.Accounts

  test "renders friends page and allows sending request", %{conn: conn} do
    current = user_fixture()
    other = user_fixture(%{"display_name" => "Other User", "nickname" => "other"})

    conn = log_in_user(conn, current)
    {:ok, lv, _html} = live(conn, ~p"/amigos")

    # Search user
    lv
    |> element("input[name=q]")
    |> render_change(%{"q" => "Other"})

    assert render(lv) =~ "Other User"

    # Send request
    lv
    |> element("button", "Solicitar amizade")
    |> render_click(%{"user_id" => other.id})

    assert Accounts.list_outgoing_friend_requests(current) |> length() == 1
  end
end
