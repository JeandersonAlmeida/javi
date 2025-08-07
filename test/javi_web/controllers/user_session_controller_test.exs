defmodule JaviWeb.UserSessionControllerTest do
  use JaviWeb.ConnCase, async: true

  import Javi.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "POST /entrar" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/entrar", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert redirected_to(conn) == ~p"/inicio"
      assert get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/entrar", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert redirected_to(conn) == ~p"/inicio"
      assert conn.resp_cookies["_javi_web_user_remember_me"]
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(~p"/entrar", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "emits error message with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/entrar", %{
          "user" => %{"email" => "unknown@example.com", "password" => "unknown"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/entrar"
    end

    test "redirects if user is already logged in", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/entrar", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == ~p"/inicio"
    end
  end

  describe "DELETE /sair" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/sair")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/sair")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end

  describe "GET /sair" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(~p"/sair")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = get(conn, ~p"/sair")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
