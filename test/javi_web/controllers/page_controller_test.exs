defmodule JaviWeb.PageControllerTest do
  use JaviWeb.ConnCase

  test "GET / redirects unauthenticated users to login", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/entrar"
  end

  test "GET / redirects authenticated users to dashboard", %{conn: conn} do
    user = Javi.AccountsFixtures.user_fixture()
    conn = conn |> log_in_user(user) |> get(~p"/")
    assert redirected_to(conn) == ~p"/inicio"
  end
end
