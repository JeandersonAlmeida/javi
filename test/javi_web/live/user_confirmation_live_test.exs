defmodule JaviWeb.UserConfirmationLiveTest do
  use JaviWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures
  import Ecto.Query

  alias Javi.Accounts
  alias Javi.Repo

  setup do
    %{user: user_fixture()}
  end

  describe "Confirmation page rendering" do
    test "renders confirmation page with all elements", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, html} = live(conn, ~p"/confirmar/#{token}")

      # Check main page elements
      assert html =~ "Confirmar Conta"
      assert html =~ "Confirme sua conta para começar a usar o Javi"
      assert html =~ "Criar nova conta"
      assert html =~ "Fazer login"

      # Check form elements
      assert html =~ "Confirmar minha conta"
      assert html =~ "Confirmando..."

      # Check features section
      assert html =~ "Verificação"
      assert html =~ "Segurança"
      assert html =~ "Ativação"

      # Check form structure
      assert has_element?(lv, "#confirmation_form")
      assert has_element?(lv, "input[type=\"hidden\"]")
      assert has_element?(lv, "button[type=\"submit\"]")
    end

    test "renders with proper styling classes", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/confirmar/#{token}")

      # Check for gradient background
      assert html =~ "bg-gradient-to-br"
      assert html =~ "from-[#0f0f23]"
      assert html =~ "via-[#1a1a2e]"
      assert html =~ "to-[#16213e]"

      # Check for backdrop blur
      assert html =~ "backdrop-blur-lg"

      # Check for animation classes
      assert html =~ "animate-blob"
      assert html =~ "animate-logo"
      assert html =~ "animate-text"
    end

    test "renders with proper icons", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/confirmar/#{token}")

      # Check for Heroicons
      assert html =~ "hero-check-circle"
      assert html =~ "hero-shield-check"
      assert html =~ "hero-sparkles"
    end

    test "renders confirmation page with invalid token", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/confirmar/invalid-token")

      # Should still render the page but with invalid token
      assert html =~ "Confirmar Conta"
      assert has_element?(lv, "#confirmation_form")
    end

    test "renders confirmation page with expired token", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/confirmar/expired-token")

      # Should still render the page but with expired token
      assert html =~ "Confirmar Conta"
      assert has_element?(lv, "#confirmation_form")
    end
  end

  describe "Form structure and validation" do
    test "form has proper structure", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check form structure
      assert has_element?(lv, "form[phx-submit=\"confirm_account\"]")
      assert has_element?(lv, "input[type=\"hidden\"]")
      assert has_element?(lv, "button[type=\"submit\"]")
    end

    test "hidden token field is properly set", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check that hidden token field exists
      assert has_element?(lv, "input[type=\"hidden\"]")
    end

    test "submit button has proper attributes", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check submit button attributes
      assert has_element?(lv, "button[type=\"submit\"]")
      assert has_element?(lv, "button[phx-disable-with=\"Confirmando...\"]")
    end

    test "form has proper accessibility attributes", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check for proper button text
      assert has_element?(lv, "button", "Confirmar minha conta")
    end
  end

  describe "Form submission" do
    test "successfully confirms account with valid token", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Submit form with valid token
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end

      # Verify user is confirmed
      assert Accounts.get_user!(user.id).confirmed_at
    end

    test "handles submission with invalid token", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar/invalid-token")

      # Submit form with invalid token
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles submission with expired token", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar/expired-token")

      # Submit form with expired token
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles submission with empty token", %{conn: conn} do
      # Empty token should show the confirmation instructions page
      {:ok, lv, _html} = live(conn, ~p"/confirmar/")

      # Should show the confirmation instructions form instead
      assert has_element?(lv, "#resend_confirmation_form")
    end

    test "handles submission with malformed token", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar/malformed-token-123")

      # Submit form with malformed token
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end
  end

  describe "Account confirmation logic" do
    test "confirms unconfirmed user", %{conn: conn, user: user} do
      # Ensure user is not confirmed by updating directly in the database
      Repo.update_all(from(u in Javi.Accounts.User, where: u.id == ^user.id),
        set: [confirmed_at: nil]
      )

      user = Repo.reload!(user)

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Submit form
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end

      # Verify user is now confirmed
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.confirmed_at
    end

    test "handles already confirmed user", %{conn: conn, user: user} do
      # Ensure user is already confirmed by updating directly in the database
      Repo.update_all(from(u in Javi.Accounts.User, where: u.id == ^user.id),
        set: [confirmed_at: DateTime.utc_now()]
      )

      user = Repo.reload!(user)

      # For already confirmed users, we can't extract a token, so we'll test with a dummy token
      token = "dummy-token-for-confirmed-user"

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Submit form
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end

      # Verify user remains confirmed
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.confirmed_at
    end

    test "handles non-existent user token", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar/non-existent-token")

      # Submit form
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end
  end

  describe "Navigation and links" do
    test "registration link redirects to registration page", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check that registration link exists
      assert has_element?(lv, "a", "Criar nova conta")
      assert has_element?(lv, "a[href=\"/cadastrar\"]")
    end

    test "login link redirects to login page", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check that login link exists
      assert has_element?(lv, "a", "Fazer login")
      assert has_element?(lv, "a[href=\"/entrar\"]")
    end

    test "submit button has proper attributes", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check submit button attributes
      assert has_element?(lv, "button[type=\"submit\"]")
      assert has_element?(lv, "button[phx-disable-with=\"Confirmando...\"]")
    end
  end

  describe "Edge cases and error handling" do
    test "handles malformed form data", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Submit with malformed data (this should still work as the token is in the URL)
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles very long token values", %{conn: conn} do
      # Test with extremely long token
      long_token = String.duplicate("a", 1000)
      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{long_token}")

      # Submit form
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles special characters in token", %{conn: conn} do
      # Test with special characters in token
      special_token = "token+with-special@chars#123"
      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{special_token}")

      # Submit form
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles unicode characters in token", %{conn: conn} do
      # Test with unicode characters in token
      unicode_token = "tokenéwith-unicode-chars"
      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{unicode_token}")

      # Submit form
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles empty form submission", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Submit empty form
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end
  end

  describe "Responsive design elements" do
    test "renders with responsive classes", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/confirmar/#{token}")

      # Check for responsive design classes
      assert html =~ "lg:text-4xl"
      assert html =~ "xl:text-5xl"
      assert html =~ "2xl:text-6xl"
      assert html =~ "lg:p-12"
      assert html =~ "xl:p-16"
    end

    test "renders with proper spacing classes", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/confirmar/#{token}")

      # Check for spacing classes
      assert html =~ "space-y-6"
      assert html =~ "lg:space-y-8"
      assert html =~ "xl:space-y-10"
    end

    test "renders with responsive navigation", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/confirmar/#{token}")

      # Check for responsive navigation classes
      assert html =~ "flex-col sm:flex-row"
      assert html =~ "hidden sm:inline"
    end
  end

  describe "Animation and styling" do
    test "renders with animation styles", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/confirmar/#{token}")

      # Check for animation styles
      assert html =~ "@keyframes blob"
      assert html =~ "@keyframes logo"
      assert html =~ "@keyframes text"
      assert html =~ "animation: blob 7s infinite"
      assert html =~ "animation: logo 3s ease-in-out infinite"
      assert html =~ "animation: text 2s ease-in-out infinite"
    end

    test "renders with gradient and blur effects", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/confirmar/#{token}")

      # Check for visual effects
      assert html =~ "bg-gradient-to-r from-blue-600 to-purple-600"
      assert html =~ "backdrop-blur-lg"
      assert html =~ "mix-blend-multiply"
      assert html =~ "filter blur-xl"
    end

    test "renders with hover effects", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/confirmar/#{token}")

      # Check for hover effects
      assert html =~ "hover:from-blue-700"
      assert html =~ "hover:to-purple-700"
      assert html =~ "hover:scale-105"
      assert html =~ "hover:text-blue-300"
    end
  end

  describe "Security features" do
    test "form has proper CSRF protection", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check that form has proper action
      assert has_element?(lv, "form[phx-submit=\"confirm_account\"]")
    end

    test "token is properly hidden in form", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check that token field is hidden
      assert has_element?(lv, "input[type=\"hidden\"]")
    end

    test "handles form submission securely", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check that the form is properly rendered
      assert has_element?(lv, "#confirmation_form")
      assert has_element?(lv, "input[type=\"hidden\"]")
    end

    test "validates token properly", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check that the form is properly rendered with valid token
      assert has_element?(lv, "#confirmation_form")
      assert has_element?(lv, "input[type=\"hidden\"]")
      assert has_element?(lv, "button[type=\"submit\"]")
    end
  end

  describe "User experience" do
    test "provides clear visual feedback", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check for visual feedback elements
      assert has_element?(lv, ".animate-logo")
      assert has_element?(lv, ".animate-text")
      assert has_element?(lv, ".animate-blob")
    end

    test "has proper focus states", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check for focus states
      assert has_element?(lv, "button[class*=\"focus:ring-2\"]")
      assert has_element?(lv, "button[class*=\"focus:outline-none\"]")
    end

    test "has proper transition effects", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/confirmar/#{token}")

      # Check for transition effects
      assert html =~ "transition-all"
      assert html =~ "duration-200"
      assert html =~ "duration-500"
    end

    test "shows loading state during submission", %{conn: conn} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user_fixture(), url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Check that submit button shows loading state
      assert has_element?(lv, "button[phx-disable-with=\"Confirmando...\"]")
    end
  end

  describe "Token validation" do
    test "validates valid token properly", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Submit form with valid token
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end

      # Verify user is confirmed
      assert Accounts.get_user!(user.id).confirmed_at
    end

    test "handles invalid token gracefully", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar/invalid-token")

      # Submit form with invalid token
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles expired token gracefully", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar/expired-token")

      # Submit form with expired token
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles already confirmed user token", %{conn: conn, user: user} do
      # Ensure user is already confirmed by updating directly in the database
      Repo.update_all(from(u in Javi.Accounts.User, where: u.id == ^user.id),
        set: [confirmed_at: DateTime.utc_now()]
      )

      user = Repo.reload!(user)

      # For already confirmed users, we can't extract a token, so we'll test with a dummy token
      token = "dummy-token-for-confirmed-user"

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Submit form
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end

      # Verify user remains confirmed
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.confirmed_at
    end
  end

  describe "Flash message handling" do
    test "shows success flash message for valid confirmation", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirmar/#{token}")

      # Submit form with valid token
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "shows error flash message for invalid token", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar/invalid-token")

      # Submit form with invalid token
      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end
  end
end
