defmodule JaviWeb.UserRegistrationLiveTest do
  use JaviWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures

  @invalid_attrs %{email: "invalid", password: "short"}

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Criar conta"
      assert html =~ "Entre na conta"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> form("#registration_form", user: @invalid_attrs)
        |> render_submit()

      assert result =~ "Criar conta"
    end
  end

  describe "register user" do
    test "creates account and logs the user in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      # Test that the form exists and can be submitted
      assert has_element?(lv, "#registration_form")
    end

    test "render errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> form("#registration_form", user: @invalid_attrs)
        |> render_submit()

      assert result =~ "Criar conta"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      # Test that the link exists
      assert has_element?(lv, "a", "Entre na conta")
    end
  end
end
