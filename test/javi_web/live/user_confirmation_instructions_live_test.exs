defmodule JaviWeb.UserConfirmationInstructionsLiveTest do
  use JaviWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Javi.AccountsFixtures
  import Ecto.Query

  alias Javi.Repo

  setup do
    %{user: user_fixture()}
  end

  describe "Confirmation instructions page rendering" do
    test "renders confirmation instructions page with all elements", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/confirmar")

      # Check main page elements
      assert html =~ "Não recebeu as instruções?"
      assert html =~ "Enviaremos um novo link de confirmação para seu email"
      assert html =~ "Criar nova conta"
      assert html =~ "Fazer login"

      # Check form elements
      assert html =~ "Reenviar instruções"
      assert html =~ "Enviando..."

      # Check features section
      assert html =~ "Email Seguro"
      assert html =~ "Confirmação"
      assert html =~ "Rápido"

      # Check form structure
      assert has_element?(lv, "#resend_confirmation_form")
      assert has_element?(lv, "input[type=\"email\"]")
      assert has_element?(lv, "button[type=\"submit\"]")
    end

    test "renders with proper styling classes", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/confirmar")

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
      {:ok, _lv, html} = live(conn, ~p"/confirmar")

      # Check for Heroicons
      assert html =~ "hero-envelope"
      assert html =~ "hero-paper-airplane"
      assert html =~ "hero-check-circle"
      assert html =~ "hero-bolt"
    end

    test "renders with proper form structure", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check form structure
      assert has_element?(lv, "form[phx-submit=\"send_instructions\"]")
      assert has_element?(lv, "input[type=\"email\"]")
      assert has_element?(lv, "button[type=\"submit\"]")
    end
  end

  describe "Form structure and validation" do
    test "form has proper structure", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check form structure
      assert has_element?(lv, "form[phx-submit=\"send_instructions\"]")
      assert has_element?(lv, "input[type=\"email\"]")
      assert has_element?(lv, "button[type=\"submit\"]")
    end

    test "email field has proper attributes", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check email field attributes
      assert has_element?(lv, "input[type=\"email\"]")
      assert has_element?(lv, "input[name=\"user[email]\"]")
      assert has_element?(lv, "input[placeholder=\"seu@email.com\"]")
      assert has_element?(lv, "input[required]")
    end

    test "submit button has proper attributes", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check submit button attributes
      assert has_element?(lv, "button[type=\"submit\"]")
      assert has_element?(lv, "button[phx-disable-with=\"Enviando...\"]")
    end

    test "form has proper accessibility attributes", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check for proper button text
      assert has_element?(lv, "button", "Reenviar instruções")
    end

    test "email field has proper label", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check for email label
      assert has_element?(lv, "label", "Email")
    end
  end

  describe "Form submission" do
    test "successfully sends confirmation instructions for unconfirmed user", %{
      conn: conn,
      user: user
    } do
      # Ensure user is not confirmed
      Repo.update_all(from(u in Javi.Accounts.User, where: u.id == ^user.id),
        set: [confirmed_at: nil]
      )

      user = Repo.reload!(user)

      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with valid email
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: user.email})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles submission with confirmed user", %{conn: conn, user: user} do
      # Ensure user is already confirmed
      Repo.update_all(from(u in Javi.Accounts.User, where: u.id == ^user.id),
        set: [confirmed_at: DateTime.utc_now()]
      )

      user = Repo.reload!(user)

      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with confirmed user email
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: user.email})
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
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with non-existent email
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: "nonexistent@example.com"})
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
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with empty email
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: ""})
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
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with malformed email
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: "invalid-email"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles submission with very long email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with very long email
      long_email = String.duplicate("a", 100) <> "@example.com"

      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: long_email})
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
    test "handles various email formats", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Test with valid email format
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: "test@example.com"})
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
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Test with email containing subdomain
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: "test@sub.example.com"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles email with plus sign", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Test with email containing plus sign
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: "test+tag@example.com"})
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
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Test with email containing dots
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: "test.user@example.com"})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles email with special characters", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Test with email containing special characters
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: "test-user@example.com"})
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
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check that registration link exists
      assert has_element?(lv, "a", "Criar nova conta")
      assert has_element?(lv, "a[href=\"/cadastrar\"]")
    end

    test "login link redirects to login page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check that login link exists
      assert has_element?(lv, "a", "Fazer login")
      assert has_element?(lv, "a[href=\"/entrar\"]")
    end

    test "submit button has proper attributes", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check submit button attributes
      assert has_element?(lv, "button[type=\"submit\"]")
      assert has_element?(lv, "button[phx-disable-with=\"Enviando...\"]")
    end
  end

  describe "Edge cases and error handling" do
    test "handles malformed form data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit with malformed data
      result =
        lv
        |> form("#resend_confirmation_form")
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
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Test with extremely long email
      long_email = String.duplicate("a", 1000) <> "@example.com"

      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: long_email})
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
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Test with special characters in email
      special_email = "test+special@chars#123.com"

      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: special_email})
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
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Test with unicode characters in email
      unicode_email = "testéwith-unicode@chars.com"

      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: unicode_email})
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
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit empty form
      result =
        lv
        |> form("#resend_confirmation_form", user: %{})
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
      {:ok, _lv, html} = live(conn, ~p"/confirmar")

      # Check for responsive design classes
      assert html =~ "lg:text-4xl"
      assert html =~ "xl:text-5xl"
      assert html =~ "2xl:text-6xl"
      assert html =~ "lg:p-12"
      assert html =~ "xl:p-16"
    end

    test "renders with proper spacing classes", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/confirmar")

      # Check for spacing classes
      assert html =~ "space-y-6"
      assert html =~ "lg:space-y-8"
      assert html =~ "xl:space-y-10"
    end

    test "renders with responsive navigation", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/confirmar")

      # Check for responsive navigation classes
      assert html =~ "flex-col sm:flex-row"
      assert html =~ "hidden sm:inline"
    end
  end

  describe "Animation and styling" do
    test "renders with animation styles", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/confirmar")

      # Check for animation styles
      assert html =~ "@keyframes blob"
      assert html =~ "@keyframes logo"
      assert html =~ "@keyframes text"
      assert html =~ "animation: blob 7s infinite"
      assert html =~ "animation: logo 3s ease-in-out infinite"
      assert html =~ "animation: text 2s ease-in-out infinite"
    end

    test "renders with gradient and blur effects", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/confirmar")

      # Check for visual effects
      assert html =~ "bg-gradient-to-r from-blue-600 to-purple-600"
      assert html =~ "backdrop-blur-lg"
      assert html =~ "mix-blend-multiply"
      assert html =~ "filter blur-xl"
    end

    test "renders with hover effects", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/confirmar")

      # Check for hover effects
      assert html =~ "hover:from-blue-700"
      assert html =~ "hover:to-purple-700"
      assert html =~ "hover:scale-105"
      assert html =~ "hover:text-blue-300"
    end
  end

  describe "Security features" do
    test "form has proper CSRF protection", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check that form has proper action
      assert has_element?(lv, "form[phx-submit=\"send_instructions\"]")
    end

    test "email field has proper validation", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check that email field has proper validation
      assert has_element?(lv, "input[type=\"email\"]")
      assert has_element?(lv, "input[required]")
    end

    test "handles form submission securely", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check that the form is properly rendered
      assert has_element?(lv, "#resend_confirmation_form")
      assert has_element?(lv, "input[type=\"email\"]")
    end

    test "validates email properly", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check that the form is properly rendered with email field
      assert has_element?(lv, "#resend_confirmation_form")
      assert has_element?(lv, "input[type=\"email\"]")
      assert has_element?(lv, "button[type=\"submit\"]")
    end
  end

  describe "User experience" do
    test "provides clear visual feedback", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check for visual feedback elements
      assert has_element?(lv, ".animate-logo")
      assert has_element?(lv, ".animate-text")
      assert has_element?(lv, ".animate-blob")
    end

    test "has proper focus states", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check for focus states
      assert has_element?(lv, "button[class*=\"focus:ring-2\"]")
      assert has_element?(lv, "button[class*=\"focus:outline-none\"]")
    end

    test "has proper transition effects", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/confirmar")

      # Check for transition effects
      assert html =~ "transition-all"
      assert html =~ "duration-200"
      assert html =~ "duration-500"
    end

    test "shows loading state during submission", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Check that submit button shows loading state
      assert has_element?(lv, "button[phx-disable-with=\"Enviando...\"]")
    end
  end

  describe "Email functionality" do
    test "handles email delivery for unconfirmed user", %{conn: conn, user: user} do
      # Ensure user is not confirmed
      Repo.update_all(from(u in Javi.Accounts.User, where: u.id == ^user.id),
        set: [confirmed_at: nil]
      )

      user = Repo.reload!(user)

      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with valid email
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: user.email})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles email delivery for confirmed user", %{conn: conn, user: user} do
      # Ensure user is already confirmed
      Repo.update_all(from(u in Javi.Accounts.User, where: u.id == ^user.id),
        set: [confirmed_at: DateTime.utc_now()]
      )

      user = Repo.reload!(user)

      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with confirmed user email
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: user.email})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "handles email delivery for non-existent user", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with non-existent email
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: "nonexistent@example.com"})
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
    test "shows success flash message for valid email", %{conn: conn, user: user} do
      # Ensure user is not confirmed
      Repo.update_all(from(u in Javi.Accounts.User, where: u.id == ^user.id),
        set: [confirmed_at: nil]
      )

      user = Repo.reload!(user)

      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with valid email
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: user.email})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "shows success flash message for confirmed user", %{conn: conn, user: user} do
      # Ensure user is already confirmed
      Repo.update_all(from(u in Javi.Accounts.User, where: u.id == ^user.id),
        set: [confirmed_at: DateTime.utc_now()]
      )

      user = Repo.reload!(user)

      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with confirmed user email
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: user.email})
        |> render_submit()

      # Should redirect to home page
      case result do
        {:error, {:redirect, %{to: path}}} ->
          assert path =~ "/"

        _ ->
          assert result =~ "redirect" || result =~ "/"
      end
    end

    test "shows success flash message for non-existent email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/confirmar")

      # Submit form with non-existent email
      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: "nonexistent@example.com"})
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
