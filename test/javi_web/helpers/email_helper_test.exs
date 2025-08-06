defmodule JaviWeb.EmailHelperTest do
  use Javi.DataCase, async: true

  alias JaviWeb.EmailHelper

  describe "email templates" do
    test "confirmation_email_template/2" do
      email = "test@example.com"
      url = "https://example.com/confirm?token=123"

      html = EmailHelper.confirmation_email_template(email, url)

      assert html =~ "Bem-vindo ao Javi!"
      assert html =~ email
      assert html =~ url
      assert html =~ "Confirmar Conta"
      assert html =~ "Sua Biblioteca de Mídia Pessoal"
    end

    test "password_reset_email_template/2" do
      email = "test@example.com"
      url = "https://example.com/reset?token=123"

      html = EmailHelper.password_reset_email_template(email, url)

      assert html =~ "Redefinir Sua Senha"
      assert html =~ email
      assert html =~ url
      assert html =~ "Redefinir Senha"
    end

    test "email_update_template/2" do
      email = "test@example.com"
      url = "https://example.com/update?token=123"

      html = EmailHelper.email_update_template(email, url)

      assert html =~ "Atualizar Seu Email"
      assert html =~ email
      assert html =~ url
      assert html =~ "Atualizar Email"
    end

    test "email_button/3 with custom color" do
      button_html = EmailHelper.email_button("Test Button", "https://example.com", "#ff0000")

      assert button_html =~ "Test Button"
      assert button_html =~ "https://example.com"
      assert button_html =~ "#ff0000"
    end

    test "email_button/2 with default color" do
      button_html = EmailHelper.email_button("Test Button", "https://example.com")

      assert button_html =~ "Test Button"
      assert button_html =~ "https://example.com"
      assert button_html =~ "#3498db"
    end
  end
end
