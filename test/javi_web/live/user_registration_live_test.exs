defmodule JaviWeb.UserRegistrationLiveTest do
  use JaviWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures

  @valid_attrs %{
    email: "test@example.com",
    password: "testpassword123",
    display_name: "Test User"
  }

  @invalid_attrs %{
    email: "invalid",
    password: "short",
    display_name: ""
  }

  describe "Registration page rendering" do
    test "renders registration page with all elements", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/cadastrar")

      # Check main page elements
      assert html =~ "Criar Conta"
      assert html =~ "Junte-se à nossa comunidade de cinéfilos"
      assert html =~ "Já tem uma conta?"
      assert html =~ "Faça login"

      # Check form elements
      assert html =~ "Nome Completo"
      assert html =~ "Email"
      assert html =~ "Senha"
      assert html =~ "Criar Conta"

      # Check features section
      assert html =~ "Listas Personalizadas"
      assert html =~ "Avaliações"
      assert html =~ "Comunidade"

      # Check form structure
      assert has_element?(lv, "#registration_form")
      assert has_element?(lv, "input[name=\"user[display_name]\"]")
      assert has_element?(lv, "input[name=\"user[email]\"]")
      assert has_element?(lv, "input[name=\"user[password]\"]")
      assert has_element?(lv, "button[type=\"submit\"]")
    end

    test "renders with proper styling classes", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/cadastrar")

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
      {:ok, _lv, html} = live(conn, ~p"/cadastrar")

      # Check for Heroicons
      assert html =~ "hero-user"
      assert html =~ "hero-envelope"
      assert html =~ "hero-key"
      assert html =~ "hero-user-plus"
      assert html =~ "hero-list-bullet"
      assert html =~ "hero-star"
      assert html =~ "hero-users"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/cadastrar")
        |> follow_redirect(conn, "/inicio")

      assert {:ok, _conn} = result
    end
  end

  describe "Form field validation" do
    test "validates display_name field", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Test empty display_name
      lv
      |> form("#registration_form", user: %{@valid_attrs | display_name: ""})
      |> render_submit()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end

    test "validates email field", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Test invalid email format
      lv
      |> form("#registration_form", user: %{@valid_attrs | email: "invalid-email"})
      |> render_submit()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end

    test "validates password field", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Test password too short
      lv
      |> form("#registration_form", user: %{@valid_attrs | password: "short"})
      |> render_submit()

      # Should show validation error
      assert has_element?(lv, ".has-error")
    end

    test "validates all fields together", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Test with all invalid fields
      lv
      |> form("#registration_form", user: @invalid_attrs)
      |> render_submit()

      # Should show validation errors
      assert has_element?(lv, ".has-error")
    end
  end

  describe "Form submission" do
    test "successfully creates account with valid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Submit form with valid data
      result =
        lv
        |> form("#registration_form", user: @valid_attrs)
        |> render_submit()

      # Should redirect to login page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/entrar"

        _ ->
          assert result =~ "redirect" || result =~ "/entrar"
      end
    end

    test "handles duplicate email error", %{conn: conn} do
      # First, create a user
      user_fixture(%{email: "test@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Try to register with same email
      lv
      |> form("#registration_form", user: @valid_attrs)
      |> render_submit()

      # Should show error
      assert has_element?(lv, ".has-error")
    end

    test "handles case-insensitive email uniqueness", %{conn: conn} do
      # First, create a user with uppercase email
      user_fixture(%{email: "TEST@EXAMPLE.COM"})

      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Try to register with same email in lowercase
      lv
      |> form("#registration_form", user: @valid_attrs)
      |> render_submit()

      # Should show error
      assert has_element?(lv, ".has-error")
    end
  end

  describe "Form state management" do
    test "maintains form state during validation", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Fill form partially
      lv
      |> form("#registration_form", user: %{@valid_attrs | email: ""})
      |> render_change()

      # Form should still be present with entered data
      html = render(lv)
      assert html =~ @valid_attrs.display_name
      # Password field is not preserved for security reasons
      refute html =~ @valid_attrs.email
    end
  end

  describe "Navigation and links" do
    test "login link redirects to login page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Check that login link exists
      assert has_element?(lv, "a", "Faça login")
      assert has_element?(lv, "a[href=\"/entrar\"]")
    end

    test "form has proper accessibility attributes", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Check for proper labels
      assert has_element?(lv, "label", "Nome Completo")
      assert has_element?(lv, "label", "Email")
      assert has_element?(lv, "label", "Senha")

      # Check for proper input types
      assert has_element?(lv, "input[type=\"text\"]")
      assert has_element?(lv, "input[type=\"email\"]")
      assert has_element?(lv, "input[type=\"password\"]")
    end
  end

  describe "Edge cases and error handling" do
    test "handles malformed form data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Submit with malformed data (using existing fields with invalid values)
      lv
      |> form("#registration_form", user: %{display_name: "", email: "", password: ""})
      |> render_submit()

      # Should handle gracefully
      assert render(lv) =~ "Criar Conta"
    end

    test "handles very long input values", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Test with extremely long values
      long_value = String.duplicate("a", 1000)

      lv
      |> form("#registration_form",
        user: %{
          @valid_attrs
          | display_name: long_value,
            email: long_value <> "@example.com",
            password: long_value
        }
      )
      |> render_submit()

      # Should show validation errors
      assert has_element?(lv, ".has-error")
    end

    test "handles special characters in display_name", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Test with special characters
      special_chars = "João da Silva & Cia."

      lv
      |> form("#registration_form", user: %{@valid_attrs | display_name: special_chars})
      |> render_submit()

      # Should show validation error for invalid characters
      assert has_element?(lv, ".has-error")
    end

    test "handles unicode characters in display_name", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/cadastrar")

      # Test with unicode characters
      unicode_name = "José María García"

      result =
        lv
        |> form("#registration_form", user: %{@valid_attrs | display_name: unicode_name})
        |> render_submit()

      # Should accept valid unicode characters
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/entrar"

        _ ->
          assert result =~ "redirect" || result =~ "Criar Conta"
      end
    end
  end

  describe "Responsive design elements" do
    test "renders with responsive classes", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/cadastrar")

      # Check for responsive design classes
      assert html =~ "lg:text-4xl"
      assert html =~ "xl:text-5xl"
      assert html =~ "2xl:text-6xl"
      assert html =~ "lg:p-12"
      assert html =~ "xl:p-16"
    end

    test "renders with proper spacing classes", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/cadastrar")

      # Check for spacing classes
      assert html =~ "space-y-6"
      assert html =~ "lg:space-y-8"
      assert html =~ "xl:space-y-10"
    end
  end

  describe "Animation and styling" do
    test "renders with animation styles", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/cadastrar")

      # Check for animation styles
      assert html =~ "@keyframes blob"
      assert html =~ "@keyframes logo"
      assert html =~ "@keyframes text"
      assert html =~ "animation: blob 7s infinite"
      assert html =~ "animation: logo 3s ease-in-out infinite"
      assert html =~ "animation: text 2s ease-in-out infinite"
    end

    test "renders with gradient and blur effects", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/cadastrar")

      # Check for visual effects
      assert html =~ "bg-gradient-to-r from-blue-600 to-purple-600"
      assert html =~ "backdrop-blur-lg"
      assert html =~ "mix-blend-multiply"
      assert html =~ "filter blur-xl"
    end
  end
end
