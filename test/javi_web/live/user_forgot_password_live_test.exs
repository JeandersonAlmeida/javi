defmodule JaviWeb.UserForgotPasswordLiveTest do
  use JaviWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures

  alias Javi.Accounts

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/reset_password")

      assert html =~ "Esqueceu sua senha?"
      assert html =~ "Enviaremos um link para redefinir sua senha no seu email"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/reset_password")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    test "sends a new reset password token", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Se seu email estiver em nosso sistema"

      assert Accounts.get_user_by_email(user.email)
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", user: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Se seu email estiver em nosso sistema"

      refute Accounts.get_user_by_email("unknown@example.com")
    end
  end
end
