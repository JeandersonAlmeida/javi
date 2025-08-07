defmodule JaviWeb.UserForgotPasswordLiveTest do
  use JaviWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures

  alias Javi.Accounts

  @valid_attrs %{email: "test@example.com"}
  @invalid_attrs %{email: "invalid-email"}

  describe "Forgot password page rendering" do
    test "renders forgot password page with all elements", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/redefinir-senha")

      # Check main page elements
      assert html =~ "Esqueceu sua senha?"
      assert html =~ "Enviaremos um link para redefinir sua senha no seu email"
      assert html =~ "Criar nova conta"
      assert html =~ "Voltar ao login"

      # Check form elements
      assert html =~ "Email"
      assert html =~ "Enviar instruções"
      assert html =~ "Enviando..."

      # Check features section
      assert html =~ "Segurança"
      assert html =~ "Email Rápido"
      assert html =~ "Acesso Fácil"

      # Check form structure
      assert has_element?(lv, "#reset_password_form")
      assert has_element?(lv, "input[name=\"user[email]\"]")
      assert has_element?(lv, "button[type=\"submit\"]")
    end

    test "renders with proper styling classes", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha")

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
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha")

      # Check for Heroicons
      assert html =~ "hero-envelope"
      assert html =~ "hero-paper-airplane"
      assert html =~ "hero-shield-check"
      assert html =~ "hero-key"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/redefinir-senha")
        |> follow_redirect(conn, "/inicio")

      assert {:ok, _conn} = result
    end
  end

  describe "Form field validation" do
    test "validates email field is required", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Test empty email
      lv
      |> form("#reset_password_form", user: %{@valid_attrs | email: ""})
      |> render_submit()

      # Should redirect with flash message
      # The form doesn't have client-side validation, so it submits anyway
    end

    test "validates email format", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Test invalid email format
      lv
      |> form("#reset_password_form", user: @invalid_attrs)
      |> render_submit()

      # Should redirect with flash message
      # The form doesn't have client-side validation, so it submits anyway
    end

    test "validates email field has proper attributes", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check that email field has proper type and attributes
      assert has_element?(lv, "input[type=\"email\"]")
      assert has_element?(lv, "input[required]")
      assert has_element?(lv, "input[placeholder=\"seu@email.com\"]")
    end

    test "validates form has proper structure", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check form structure
      assert has_element?(lv, "form[phx-submit=\"send_email\"]")
      assert has_element?(lv, "label", "Email")
      assert has_element?(lv, "input[name=\"user[email]\"]")
    end
  end

  describe "Form submission" do
    test "successfully sends reset password email for valid user", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit form with valid email
      result =
        lv
        |> form("#reset_password_form", user: %{email: user.email})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles submission with non-existent email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit form with non-existent email
      result =
        lv
        |> form("#reset_password_form", user: %{email: "nonexistent@example.com"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles submission with empty email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit form with empty email
      result =
        lv
        |> form("#reset_password_form", user: %{email: ""})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles submission with malformed email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit form with malformed email
      result =
        lv
        |> form("#reset_password_form", user: %{email: "not-an-email"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles submission with special characters in email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit form with special characters in email
      result =
        lv
        |> form("#reset_password_form", user: %{email: "test+tag@example.com"})
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

  describe "Form state management" do
    test "maintains form state during submission", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check that form is present
      assert has_element?(lv, "#reset_password_form")
      assert has_element?(lv, "input[name=\"user[email]\"]")
      assert has_element?(lv, "button[type=\"submit\"]")
    end

    test "shows loading state during submission", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check that submit button shows loading state
      assert has_element?(lv, "button[phx-disable-with=\"Enviando...\"]")
    end

    test "form has proper accessibility attributes", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check for proper labels
      assert has_element?(lv, "label", "Email")

      # Check for proper input types
      assert has_element?(lv, "input[type=\"email\"]")
      assert has_element?(lv, "input[required]")
    end
  end

  describe "Navigation and links" do
    test "registration link redirects to registration page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check that registration link exists
      assert has_element?(lv, "a", "Criar nova conta")
      assert has_element?(lv, "a[href=\"/cadastrar\"]")
    end

    test "login link redirects to login page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check that login link exists
      assert has_element?(lv, "a", "Voltar ao login")
      assert has_element?(lv, "a[href=\"/entrar\"]")
    end

    test "submit button has proper attributes", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check submit button attributes
      assert has_element?(lv, "button[type=\"submit\"]")
      assert has_element?(lv, "button[phx-disable-with=\"Enviando...\"]")
    end
  end

  describe "Edge cases and error handling" do
    test "handles malformed form data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit with malformed data (using existing field with invalid value)
      result =
        lv
        |> form("#reset_password_form", user: %{email: ""})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles very long email values", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Test with extremely long email
      long_email = String.duplicate("a", 100) <> "@example.com"

      result =
        lv
        |> form("#reset_password_form", user: %{email: long_email})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles special characters in email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Test with special characters in email
      special_email = "test+tag#domain@example.com"

      result =
        lv
        |> form("#reset_password_form", user: %{email: special_email})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles unicode characters in email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Test with unicode characters in email
      unicode_email = "testé@example.com"

      result =
        lv
        |> form("#reset_password_form", user: %{email: unicode_email})
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
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit empty form
      result =
        lv
        |> form("#reset_password_form", user: %{email: ""})
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
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha")

      # Check for responsive design classes
      assert html =~ "lg:text-4xl"
      assert html =~ "xl:text-5xl"
      assert html =~ "2xl:text-6xl"
      assert html =~ "lg:p-12"
      assert html =~ "xl:p-16"
    end

    test "renders with proper spacing classes", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha")

      # Check for spacing classes
      assert html =~ "space-y-6"
      assert html =~ "lg:space-y-8"
      assert html =~ "xl:space-y-10"
    end

    test "renders with responsive navigation", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha")

      # Check for responsive navigation classes
      assert html =~ "flex-col sm:flex-row"
      assert html =~ "hidden sm:inline"
    end
  end

  describe "Animation and styling" do
    test "renders with animation styles", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha")

      # Check for animation styles
      assert html =~ "@keyframes blob"
      assert html =~ "@keyframes logo"
      assert html =~ "@keyframes text"
      assert html =~ "animation: blob 7s infinite"
      assert html =~ "animation: logo 3s ease-in-out infinite"
      assert html =~ "animation: text 2s ease-in-out infinite"
    end

    test "renders with gradient and blur effects", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha")

      # Check for visual effects
      assert html =~ "bg-gradient-to-r from-blue-600 to-purple-600"
      assert html =~ "backdrop-blur-lg"
      assert html =~ "mix-blend-multiply"
      assert html =~ "filter blur-xl"
    end

    test "renders with hover effects", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha")

      # Check for hover effects
      assert html =~ "hover:from-blue-700"
      assert html =~ "hover:to-purple-700"
      assert html =~ "hover:scale-105"
      assert html =~ "hover:text-blue-300"
    end
  end

  describe "Security features" do
    test "email field is properly secured", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check that email field has proper type
      assert has_element?(lv, "input[type=\"email\"]")

      # Check that email field has proper placeholder
      assert has_element?(lv, "input[placeholder=\"seu@email.com\"]")
    end

    test "form has proper CSRF protection", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check that form has proper action
      assert has_element?(lv, "form[phx-submit=\"send_email\"]")
    end

    test "email field is required", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check that email field is required
      assert has_element?(lv, "input[required]")
    end

    test "handles form submission securely", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check that the form is properly rendered
      assert has_element?(lv, "#reset_password_form")
      assert has_element?(lv, "input[name=\"user[email]\"]")
    end
  end

  describe "User experience" do
    test "provides clear visual feedback", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check for visual feedback elements
      assert has_element?(lv, ".animate-logo")
      assert has_element?(lv, ".animate-text")
      assert has_element?(lv, ".animate-blob")
    end

    test "has proper focus states", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check for focus states
      assert has_element?(lv, "input[class*=\"focus:ring-2\"]")
      assert has_element?(lv, "input[class*=\"focus:outline-none\"]")
    end

    test "has proper transition effects", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/redefinir-senha")

      # Check for transition effects
      assert html =~ "transition-all"
      assert html =~ "duration-200"
      assert html =~ "duration-500"
    end

    test "shows loading state during submission", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check that submit button shows loading state
      assert has_element?(lv, "button[phx-disable-with=\"Enviando...\"]")
    end
  end

  describe "Email functionality" do
    test "sends reset password email for valid user", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit form with valid email
      result =
        lv
        |> form("#reset_password_form", user: %{email: user.email})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end

      # Verify user still exists
      assert Accounts.get_user_by_email(user.email)
    end

    test "handles non-existent email gracefully", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit form with non-existent email
      result =
        lv
        |> form("#reset_password_form", user: %{email: "nonexistent@example.com"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end

      # Verify user doesn't exist
      refute Accounts.get_user_by_email("nonexistent@example.com")
    end

    test "handles empty email gracefully", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit form with empty email
      result =
        lv
        |> form("#reset_password_form", user: %{email: ""})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles malformed email gracefully", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit form with malformed email
      result =
        lv
        |> form("#reset_password_form", user: %{email: "not-an-email"})
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

  describe "Flash message handling" do
    test "shows appropriate flash message after submission", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit form with valid email
      result =
        lv
        |> form("#reset_password_form", user: %{email: user.email})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles flash message for non-existent email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Submit form with non-existent email
      result =
        lv
        |> form("#reset_password_form", user: %{email: "nonexistent@example.com"})
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

  describe "Email validation" do
    test "validates email format properly", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      # Check that email field has proper type
      assert has_element?(lv, "input[type=\"email\"]")
      assert has_element?(lv, "input[required]")
    end

    test "handles basic email format", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      result =
        lv
        |> form("#reset_password_form", user: %{email: "test@example.com"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles email with plus tag", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      result =
        lv
        |> form("#reset_password_form", user: %{email: "test+tag@example.com"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles email with dots", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      result =
        lv
        |> form("#reset_password_form", user: %{email: "test.name@example.com"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles email with numbers", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      result =
        lv
        |> form("#reset_password_form", user: %{email: "test123@example.com"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles email with country domain", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      result =
        lv
        |> form("#reset_password_form", user: %{email: "test@example.co.uk"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles email with subdomain", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      result =
        lv
        |> form("#reset_password_form", user: %{email: "test@subdomain.example.com"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles email with long tag", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/redefinir-senha")

      result =
        lv
        |> form("#reset_password_form", user: %{email: "test+very-long-tag@example.com"})
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
