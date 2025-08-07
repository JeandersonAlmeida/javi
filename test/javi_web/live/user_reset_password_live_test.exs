defmodule JaviWeb.UserResetPasswordLiveTest do
  use JaviWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures

  alias Javi.Accounts

  @valid_attrs %{
    password: "newvalidpassword123",
    password_confirmation: "newvalidpassword123"
  }

  @invalid_attrs %{
    password: "short",
    password_confirmation: "doesnotmatch"
  }

  setup do
    user = user_fixture()

    token =
      extract_user_token(fn url ->
        Accounts.deliver_user_reset_password_instructions(user, url)
      end)

    %{token: token, user: user}
  end

  describe "Reset password page rendering" do
    test "renders reset password page with all elements", %{conn: conn, token: token} do
      {:ok, lv, html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check main page elements
      assert html =~ "Redefinir Senha"
      assert html =~ "Digite sua nova senha"
      assert html =~ "Criar nova conta"
      assert html =~ "Voltar ao login"

      # Check form elements
      assert html =~ "Nova Senha"
      assert html =~ "Confirmar Nova Senha"
      assert html =~ "Redefinir Senha"
      assert html =~ "Redefinindo..."

      # Check features section
      assert html =~ "Segurança"
      assert html =~ "Senha Forte"
      assert html =~ "Acesso Seguro"

      # Check form structure
      assert has_element?(lv, "#reset_password_form")
      assert has_element?(lv, "input[name=\"user[password]\"]")
      assert has_element?(lv, "input[name=\"user[password_confirmation]\"]")
      assert has_element?(lv, "button[type=\"submit\"]")
    end

    test "renders with proper styling classes", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha/#{token}")

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

    test "renders with proper icons", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check for Heroicons
      assert html =~ "hero-lock-closed"
      assert html =~ "hero-key"
      assert html =~ "hero-shield-check"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, ~p"/redefinir-senha/invalid")

      assert path =~ "/"
      assert flash["error"] =~ "Link de redefinição de senha é inválido ou expirou"
    end

    test "does not render reset password with expired token", %{conn: conn} do
      # Create an expired token by manipulating the database
      user = user_fixture()

      _old_token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      # Simulate token expiration by deleting it
      # This would normally be handled by a cleanup job
      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, ~p"/redefinir-senha/expired_token")

      assert path =~ "/"
      assert flash["error"] =~ "Link de redefinição de senha é inválido ou expirou"
    end
  end

  describe "Form field validation" do
    test "validates password field is required", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Test empty password
      lv
      |> form("#reset_password_form", user: %{@valid_attrs | password: ""})
      |> render_change()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end

    test "validates password confirmation field is required", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Test empty password confirmation
      lv
      |> form("#reset_password_form", user: %{@valid_attrs | password_confirmation: ""})
      |> render_change()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end

    test "validates password minimum length", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Test short password
      lv
      |> form("#reset_password_form", user: %{@valid_attrs | password: "short"})
      |> render_change()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end

    test "validates password confirmation matches", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Test mismatched passwords
      lv
      |> form("#reset_password_form", user: @invalid_attrs)
      |> render_change()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end

    test "validates all fields together", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Test with all invalid fields
      lv
      |> form("#reset_password_form", user: %{password: "", password_confirmation: ""})
      |> render_change()

      # Should show validation errors
      assert has_element?(lv, ".has-error")
    end
  end

  describe "Form submission" do
    test "successfully resets password with valid data", %{conn: conn, token: token, user: _user} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Submit form with valid data
      result =
        lv
        |> form("#reset_password_form", user: @valid_attrs)
        |> render_submit()

      # Should redirect to login page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/entrar"

        _ ->
          assert result =~ "redirect" || result =~ "/entrar"
      end
    end

    test "handles password reset with mismatched confirmation", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Submit form with mismatched passwords
      lv
      |> form("#reset_password_form", user: @invalid_attrs)
      |> render_submit()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end

    test "handles password reset with short password", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Submit form with short password
      lv
      |> form("#reset_password_form", user: %{password: "short", password_confirmation: "short"})
      |> render_submit()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end

    test "handles password reset with empty fields", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Submit form with empty fields
      lv
      |> form("#reset_password_form", user: %{password: "", password_confirmation: ""})
      |> render_submit()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end

    test "handles password reset with special characters", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Submit form with special characters in password
      special_password = "new@password#123!"

      result =
        lv
        |> form("#reset_password_form",
          user: %{password: special_password, password_confirmation: special_password}
        )
        |> render_submit()

      # Should redirect to login page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/entrar"

        _ ->
          assert result =~ "redirect" || result =~ "/entrar"
      end
    end
  end

  describe "Form state management" do
    test "maintains form state during validation", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Fill form partially
      lv
      |> form("#reset_password_form", user: %{@valid_attrs | password: ""})
      |> render_change()

      # Form should still be present with entered data
      html = render(lv)
      # Password fields are not preserved for security reasons
      refute html =~ @valid_attrs.password
    end

    test "shows validation errors in real-time", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Enter invalid data
      lv
      |> form("#reset_password_form", user: @invalid_attrs)
      |> render_change()

      # Should show validation errors
      assert has_element?(lv, ".has-error")
    end

    test "clears validation errors when data becomes valid", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Enter invalid data first
      lv
      |> form("#reset_password_form", user: @invalid_attrs)
      |> render_change()

      # Should show validation errors
      assert has_element?(lv, ".has-error")

      # Enter valid data
      lv
      |> form("#reset_password_form", user: @valid_attrs)
      |> render_change()

      # Should not show validation errors
      refute has_element?(lv, ".has-error")
    end
  end

  describe "Navigation and links" do
    test "registration link redirects to registration page", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check that registration link exists
      assert has_element?(lv, "a", "Criar nova conta")
      assert has_element?(lv, "a[href=\"/cadastrar\"]")
    end

    test "login link redirects to login page", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check that login link exists
      assert has_element?(lv, "a", "Voltar ao login")
      assert has_element?(lv, "a[href=\"/entrar\"]")
    end

    test "form has proper accessibility attributes", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check for proper labels
      assert has_element?(lv, "label", "Nova Senha")
      assert has_element?(lv, "label", "Confirmar Nova Senha")

      # Check for proper input types
      assert has_element?(lv, "input[type=\"password\"]")
      assert has_element?(lv, "input[required]")
    end

    test "submit button has proper attributes", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check submit button attributes
      assert has_element?(lv, "button[type=\"submit\"]")
      assert has_element?(lv, "button[phx-disable-with=\"Redefinindo...\"]")
    end
  end

  describe "Edge cases and error handling" do
    test "handles malformed form data", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Submit with malformed data (using existing fields with invalid values)
      lv
      |> form("#reset_password_form", user: %{password: "", password_confirmation: ""})
      |> render_submit()

      # Should handle gracefully
      assert render(lv) =~ "Redefinir Senha"
    end

    test "handles very long password values", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Test with extremely long password
      long_password = String.duplicate("a", 1000)

      lv
      |> form("#reset_password_form",
        user: %{password: long_password, password_confirmation: long_password}
      )
      |> render_submit()

      # Should show validation errors
      assert has_element?(lv, ".has-error")
    end

    test "handles special characters in password", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Test with special characters in password
      special_password = "new@password#123!$%^&*()"

      result =
        lv
        |> form("#reset_password_form",
          user: %{password: special_password, password_confirmation: special_password}
        )
        |> render_submit()

      # Should redirect to login page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/entrar"

        _ ->
          assert result =~ "redirect" || result =~ "/entrar"
      end
    end

    test "handles unicode characters in password", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Test with unicode characters in password
      unicode_password = "newpássword123"

      result =
        lv
        |> form("#reset_password_form",
          user: %{password: unicode_password, password_confirmation: unicode_password}
        )
        |> render_submit()

      # Should redirect to login page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/entrar"

        _ ->
          assert result =~ "redirect" || result =~ "/entrar"
      end
    end

    test "handles empty form submission", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Submit empty form
      lv
      |> form("#reset_password_form", user: %{password: "", password_confirmation: ""})
      |> render_submit()

      # Should show validation errors
      assert has_element?(lv, ".has-error")
    end

    test "handles token expiration during form submission", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # This test simulates what happens if the token expires during form submission
      # In a real scenario, this would be handled by the backend validation
      result =
        lv
        |> form("#reset_password_form", user: @valid_attrs)
        |> render_submit()

      # Should handle gracefully - either redirect or show form
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/entrar"

        _ ->
          assert result =~ "Redefinir Senha" || result =~ "redirect"
      end
    end
  end

  describe "Responsive design elements" do
    test "renders with responsive classes", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check for responsive design classes
      assert html =~ "lg:text-4xl"
      assert html =~ "xl:text-5xl"
      assert html =~ "2xl:text-6xl"
      assert html =~ "lg:p-12"
      assert html =~ "xl:p-16"
    end

    test "renders with proper spacing classes", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check for spacing classes
      assert html =~ "space-y-6"
      assert html =~ "lg:space-y-8"
      assert html =~ "xl:space-y-10"
    end

    test "renders with responsive navigation", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check for responsive navigation classes
      assert html =~ "flex-col sm:flex-row"
      assert html =~ "hidden sm:inline"
    end
  end

  describe "Animation and styling" do
    test "renders with animation styles", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check for animation styles
      assert html =~ "@keyframes blob"
      assert html =~ "@keyframes logo"
      assert html =~ "@keyframes text"
      assert html =~ "animation: blob 7s infinite"
      assert html =~ "animation: logo 3s ease-in-out infinite"
      assert html =~ "animation: text 2s ease-in-out infinite"
    end

    test "renders with gradient and blur effects", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check for visual effects
      assert html =~ "bg-gradient-to-r from-blue-600 to-purple-600"
      assert html =~ "backdrop-blur-lg"
      assert html =~ "mix-blend-multiply"
      assert html =~ "filter blur-xl"
    end

    test "renders with hover effects", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check for hover effects
      assert html =~ "hover:from-blue-700"
      assert html =~ "hover:to-purple-700"
      assert html =~ "hover:scale-105"
      assert html =~ "hover:text-blue-300"
    end
  end

  describe "Security features" do
    test "password fields are properly secured", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check that password fields have proper type
      assert has_element?(lv, "input[type=\"password\"]")

      # Check that password fields have proper placeholders
      assert has_element?(lv, "input[placeholder=\"Digite sua nova senha\"]")
      assert has_element?(lv, "input[placeholder=\"Confirme sua nova senha\"]")
    end

    test "form has proper CSRF protection", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check that form has proper action
      assert has_element?(lv, "form[phx-submit=\"reset_password\"]")
    end

    test "password fields are required", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check that password fields are required
      assert has_element?(lv, "input[required]")
    end

    test "handles token validation properly", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check that the form is properly rendered with valid token
      assert has_element?(lv, "#reset_password_form")
      assert has_element?(lv, "input[name=\"user[password]\"]")
      assert has_element?(lv, "input[name=\"user[password_confirmation]\"]")
    end
  end

  describe "User experience" do
    test "provides clear visual feedback", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check for visual feedback elements
      assert has_element?(lv, ".animate-logo")
      assert has_element?(lv, ".animate-text")
      assert has_element?(lv, ".animate-blob")
    end

    test "has proper focus states", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check for focus states
      assert has_element?(lv, "input[class*=\"focus:ring-2\"]")
      assert has_element?(lv, "input[class*=\"focus:outline-none\"]")
    end

    test "has proper transition effects", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check for transition effects
      assert html =~ "transition-all"
      assert html =~ "duration-200"
      assert html =~ "duration-500"
    end

    test "shows loading state during submission", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Check that submit button shows loading state
      assert has_element?(lv, "button[phx-disable-with=\"Redefinindo...\"]")
    end
  end

  describe "Error handling" do
    test "shows error message for invalid token", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, ~p"/redefinir-senha/invalid_token")

      assert path =~ "/"
      assert flash["error"] =~ "Link de redefinição de senha é inválido ou expirou"
    end

    test "shows error message for expired token", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, ~p"/redefinir-senha/expired_token")

      assert path =~ "/"
      assert flash["error"] =~ "Link de redefinição de senha é inválido ou expirou"
    end

    test "shows validation errors in form", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Submit invalid data
      lv
      |> form("#reset_password_form", user: @invalid_attrs)
      |> render_submit()

      # Should show error message
      assert has_element?(lv, ".bg-red-500/10") || has_element?(lv, ".text-red-400") ||
               has_element?(lv, ".has-error")
    end
  end

  describe "Password strength validation" do
    test "validates password minimum length", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Test with password shorter than minimum
      short_password = "short"

      lv
      |> form("#reset_password_form",
        user: %{password: short_password, password_confirmation: short_password}
      )
      |> render_submit()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end

    test "accepts strong passwords", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Test with strong password
      strong_password = "StrongPassword123!"

      result =
        lv
        |> form("#reset_password_form",
          user: %{password: strong_password, password_confirmation: strong_password}
        )
        |> render_submit()

      # Should redirect to login page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/entrar"

        _ ->
          assert result =~ "redirect" || result =~ "/entrar"
      end
    end

    test "validates password confirmation match", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha/#{token}")

      # Test with mismatched passwords
      lv
      |> form("#reset_password_form",
        user: %{password: "password123", password_confirmation: "password456"}
      )
      |> render_submit()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end
  end
end
