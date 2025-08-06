defmodule JaviWeb.EmailHelper do
  @moduledoc """
  Helper functions for creating email templates.
  """

  @doc """
  Creates a base HTML email template with consistent styling.
  """
  def base_email_template(title, content) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>#{title}</title>
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f8f9fa;">
      <div style="max-width: 600px; margin: 0 auto; background-color: white; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px 20px; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 28px; font-weight: 300;">Javi</h1>
          <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 16px;">Sua Biblioteca de Mídia Pessoal</p>
        </div>

        <!-- Content -->
        <div style="padding: 40px 20px;">
          #{content}
        </div>

        <!-- Footer -->
        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #e9ecef;">
          <p style="margin: 0; color: #6c757d; font-size: 14px;">
            Esta é uma mensagem automática do Javi.<br>
            Se você tiver alguma dúvida, entre em contato com nossa equipe de suporte.
          </p>
        </div>
      </div>
    </body>
    </html>
    """
  end

  @doc """
  Creates a styled button for email templates.
  """
  def email_button(text, url, color \\ "#3498db") do
    """
    <div style="text-align: center; margin: 30px 0;">
      <a href="#{url}" style="background-color: #{color}; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; display: inline-block; font-weight: 500; font-size: 16px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
        #{text}
      </a>
    </div>
    """
  end

  @doc """
  Creates a confirmation email template.
  """
  def confirmation_email_template(user_email, url) do
    content = """
    <h2 style="color: #2c3e50; margin-top: 0; font-size: 24px;">Bem-vindo ao Javi!</h2>
    <p style="font-size: 16px; color: #555;">Olá #{user_email},</p>
    <p style="font-size: 16px; color: #555;">Obrigado por se cadastrar! Para completar seu registro e começar a organizar sua biblioteca de mídia, confirme sua conta clicando no botão abaixo:</p>

    #{email_button("Confirmar Conta", url, "#3498db")}

    <p style="font-size: 14px; color: #6c757d;">Se o botão não funcionar, você pode copiar e colar este link no seu navegador:</p>
    <p style="word-break: break-all; color: #7f8c8d; font-size: 14px; background-color: #f8f9fa; padding: 10px; border-radius: 4px; margin: 10px 0;">#{url}</p>

    <p style="font-size: 16px; color: #555;">Se você não criou uma conta conosco, ignore este email.</p>
    """

    base_email_template("Confirmar Sua Conta", content)
  end

  @doc """
  Creates a password reset email template.
  """
  def password_reset_email_template(user_email, url) do
    content = """
    <h2 style="color: #2c3e50; margin-top: 0; font-size: 24px;">Redefinir Sua Senha</h2>
    <p style="font-size: 16px; color: #555;">Olá #{user_email},</p>
    <p style="font-size: 16px; color: #555;">Recebemos uma solicitação para redefinir sua senha. Clique no botão abaixo para criar uma nova senha:</p>

    #{email_button("Redefinir Senha", url, "#e74c3c")}

    <p style="font-size: 14px; color: #6c757d;">Se o botão não funcionar, você pode copiar e colar este link no seu navegador:</p>
    <p style="word-break: break-all; color: #7f8c8d; font-size: 14px; background-color: #f8f9fa; padding: 10px; border-radius: 4px; margin: 10px 0;">#{url}</p>

    <p style="font-size: 16px; color: #555;">Se você não solicitou esta alteração, ignore este email.</p>
    """

    base_email_template("Redefinir Sua Senha", content)
  end

  @doc """
  Creates an email update template.
  """
  def email_update_template(user_email, url) do
    content = """
    <h2 style="color: #2c3e50; margin-top: 0; font-size: 24px;">Atualizar Seu Email</h2>
    <p style="font-size: 16px; color: #555;">Olá #{user_email},</p>
    <p style="font-size: 16px; color: #555;">Recebemos uma solicitação para atualizar seu endereço de email. Clique no botão abaixo para confirmar esta alteração:</p>

    #{email_button("Atualizar Email", url, "#f39c12")}

    <p style="font-size: 14px; color: #6c757d;">Se o botão não funcionar, você pode copiar e colar este link no seu navegador:</p>
    <p style="word-break: break-all; color: #7f8c8d; font-size: 14px; background-color: #f8f9fa; padding: 10px; border-radius: 4px; margin: 10px 0;">#{url}</p>

    <p style="font-size: 16px; color: #555;">Se você não solicitou esta alteração, ignore este email.</p>
    """

    base_email_template("Atualizar Seu Email", content)
  end
end
