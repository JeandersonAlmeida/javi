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

      # Check initial step - look for onboarding content
      assert has_element?(view, "text", "onboarding") || has_element?(view, "text", "Javi")

      # Go to next step
      view |> element("button", "Próximo") |> render_click()
      # Check for next step content
      assert has_element?(view, "button", "Próximo") || has_element?(view, "button", "Anterior")

      # Go to previous step
      view |> element("button", "Anterior") |> render_click()
      # Check we're back to initial step
      assert has_element?(view, "button", "Próximo")
    end

    test "skips onboarding", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      view |> element("button", "Pular") |> render_click()
      assert_redirect(view, ~p"/inicio")
    end

    test "completes onboarding", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Navigate through all steps
      for _ <- 1..4 do
        view |> element("button", "Próximo") |> render_click()
      end

      # Click "Próximo" on final step (the button text is "Próximo" not "Começar")
      view |> element("button", "Próximo") |> render_click()
      assert_redirect(view, ~p"/inicio")
    end
  end
end
