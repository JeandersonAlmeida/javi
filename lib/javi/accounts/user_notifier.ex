defmodule Javi.Accounts.UserNotifier do
  import Swoosh.Email

  alias Javi.Mailer
  alias JaviWeb.EmailHelper

  # Delivers the email with HTML support
  defp deliver_with_html(recipient, subject, text_body, html_body) do
    email =
      new()
      |> to(recipient)
      |> from({"Javi", "noreply@javi.ornender.com"})
      |> subject(subject)
      |> text_body(text_body)
      |> html_body(html_body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    text_body = """
    ==============================

    Olá #{user.email},

    Você pode confirmar sua conta visitando o link abaixo:

    #{url}

    Se você não criou uma conta conosco, ignore este email.

    ==============================
    """

    html_body = EmailHelper.confirmation_email_template(user.email, url)

    deliver_with_html(user.email, "Confirmar Sua Conta - Javi", text_body, html_body)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    text_body = """
    ==============================

    Olá #{user.email},

    Você pode redefinir sua senha visitando o link abaixo:

    #{url}

    Se você não solicitou esta alteração, ignore este email.

    ==============================
    """

    html_body = EmailHelper.password_reset_email_template(user.email, url)

    deliver_with_html(user.email, "Redefinir Sua Senha - Javi", text_body, html_body)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    text_body = """
    ==============================

    Olá #{user.email},

    Você pode alterar seu email visitando o link abaixo:

    #{url}

    Se você não solicitou esta alteração, ignore este email.

    ==============================
    """

    html_body = EmailHelper.email_update_template(user.email, url)

    deliver_with_html(user.email, "Atualizar Seu Email - Javi", text_body, html_body)
  end
end
