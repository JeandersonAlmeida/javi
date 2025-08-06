defmodule Javi.Accounts.UserNotifierTest do
  use Javi.DataCase, async: true

  alias Javi.Accounts.UserNotifier
  alias Javi.AccountsFixtures

  describe "email notifications" do
    test "deliver_confirmation_instructions/2" do
      user = AccountsFixtures.user_fixture()
      url = "https://example.com/confirm?token=123"

      assert {:ok, email} = UserNotifier.deliver_confirmation_instructions(user, url)
      assert email.to == [{"", user.email}]
      assert email.subject == "Confirmar Sua Conta - Javi"
      assert email.html_body =~ "Bem-vindo ao Javi!"
      assert email.html_body =~ url
    end

    test "deliver_reset_password_instructions/2" do
      user = AccountsFixtures.user_fixture()
      url = "https://example.com/reset?token=123"

      assert {:ok, email} = UserNotifier.deliver_reset_password_instructions(user, url)
      assert email.to == [{"", user.email}]
      assert email.subject == "Redefinir Sua Senha - Javi"
      assert email.html_body =~ "Redefinir Sua Senha"
      assert email.html_body =~ url
    end

    test "deliver_update_email_instructions/2" do
      user = AccountsFixtures.user_fixture()
      url = "https://example.com/update-email?token=123"

      assert {:ok, email} = UserNotifier.deliver_update_email_instructions(user, url)
      assert email.to == [{"", user.email}]
      assert email.subject == "Atualizar Seu Email - Javi"
      assert email.html_body =~ "Atualizar Seu Email"
      assert email.html_body =~ url
    end
  end
end
