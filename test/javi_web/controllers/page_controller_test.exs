defmodule JaviWeb.PageControllerTest do
  use JaviWeb.ConnCase

  test "GET / renders landing for unauthenticated users", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Javi"
  end

  test "GET / renders landing for authenticated users", %{conn: conn} do
    user = Javi.AccountsFixtures.user_fixture()
    conn = conn |> log_in_user(user) |> get(~p"/")
    assert html_response(conn, 200) =~ "Javi"
  end
end
