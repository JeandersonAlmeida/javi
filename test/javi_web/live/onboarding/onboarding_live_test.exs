defmodule JaviWeb.Onboarding.OnboardingLiveTest do
  use JaviWeb.ConnCase

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  describe "Onboarding" do
    setup [:create_user]

    test "renders onboarding page", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _index_live, html} = live(conn, ~p"/onboarding")

      assert html =~ "Bem-vindo ao Javi"
      assert html =~ "Sua plataforma completa para organizar filmes e séries"
    end

    test "navigates through steps", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Check initial step
      assert has_element?(view, "text", "Bem-vindo ao Javi")

      # Go to next step
      view |> element("button", "Próximo") |> render_click()
      assert has_element?(view, "text", "Explore Milhares de Títulos")

      # Go to previous step
      view |> element("button", "Anterior") |> render_click()
      assert has_element?(view, "text", "Bem-vindo ao Javi")
    end

    test "skips onboarding", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      view |> element("button", "Pular") |> render_click()
      assert_redirect(view, ~p"/home")
    end

    test "completes onboarding", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Navigate through all steps
      for _ <- 1..4 do
        view |> element("button", "Próximo") |> render_click()
      end

      # Click "Começar" on final step
      view |> element("button", "Começar") |> render_click()
      assert_redirect(view, ~p"/home")
    end
  end
end
