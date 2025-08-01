defmodule JaviWeb.LandingControllerTest do
  use JaviWeb.ConnCase

  test "GET / when user is not authenticated shows landing page", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Descubra Seu"
    assert html_response(conn, 200) =~ "Começar Grátis"
    assert html_response(conn, 200) =~ "Entrar"
  end

  test "GET / when user is authenticated shows landing page", %{conn: conn} do
    user = Javi.AccountsFixtures.user_fixture(%{display_name: "Test User"})
    conn = conn |> log_in_user(user) |> get(~p"/")
    assert html_response(conn, 200) =~ "Descubra Seu"
    assert html_response(conn, 200) =~ "Começar Grátis"
    assert html_response(conn, 200) =~ "Entrar"
  end
end
