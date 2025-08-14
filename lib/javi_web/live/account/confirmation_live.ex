defmodule JaviWeb.Account.ConfirmationLive do
  use JaviWeb, :live_view

  alias Javi.Accounts

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-[#0f0f23] via-[#1a1a2e] to-[#16213e] flex items-center justify-center p-4 lg:p-8">
      <!-- Background Animation -->
      <div class="absolute inset-0 overflow-hidden">
        <div class="absolute -top-40 -right-40 w-80 h-80 bg-purple-500 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-blob">
        </div>
        <div class="absolute -bottom-40 -left-40 w-80 h-80 bg-blue-500 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-blob animation-delay-2000">
        </div>
        <div class="absolute top-40 left-40 w-80 h-80 bg-pink-500 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-blob animation-delay-4000">
        </div>
      </div>
      
    <!-- Main Card -->
      <div class="relative w-full max-w-xllg:max-w-lg xl:max-w-xl 2xl:max-w-2xl">
        <!-- Card Container -->
        <div class="bg-white/10 backdrop-blur-lg rounded-3xl shadow-2xl border border-white/20 p-8 lg:p-12 xl:p-16 transform transition-all duration-500 hover:scale-105">
          <!-- Header -->
          <div class="text-center mb-8 lg:mb-12 xl:mb-16">
            <div class="w-20 h-20 lg:w-24 lg:h-24 xl:w-28 xl:h-28 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-4 lg:mb-6 xl:mb-8 shadow-lg animate-logo">
              <div class="text-white font-bold text-xl lg:text-2xl xl:text-3xl tracking-wider animate-text">
                JAVI
              </div>
            </div>
            <h1 class="text-3xl lg:text-4xl xl:text-5xl 2xl:text-6xl font-bold text-white mb-2 lg:mb-4 xl:mb-6">
              Confirmar Conta
            </h1>
            <p class="text-gray-300 text-sm lg:text-base xl:text-lg">
              Confirme sua conta para começar a usar o Javi
            </p>
          </div>
          
    <!-- Form -->
          <.form
            for={@form}
            id="confirmation_form"
            phx-submit="confirm_account"
            class="space-y-6 lg:space-y-8 xl:space-y-10"
          >
            <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
            
    <!-- Submit Button -->
            <button
              type="submit"
              class="w-full bg-gradient-to-r from-blue-600 to-purple-600 text-white font-semibold py-3 lg:py-4 xl:py-5 px-4 lg:px-6 xl:px-8 rounded-xl hover:from-blue-700 hover:to-purple-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-gray-900 transition-all duration-200 transform hover:scale-105 shadow-lg text-base lg:text-lg xl:text-xl"
              phx-disable-with="Confirmando..."
            >
              <span class="flex items-center justify-center">
                <.icon name="hero-check-circle" class="w-5 h-5 lg:w-6 lg:h-6 xl:w-7 xl:h-7 mr-2" />
                Confirmar minha conta
              </span>
            </button>
          </.form>
          
    <!-- Links -->
          <div class="mt-6 lg:mt-8 xl:mt-10 text-center space-y-4">
            <div class="flex flex-col sm:flex-row gap-2 sm:gap-4 justify-center items-center">
              <.link
                href={~p"/cadastrar"}
                class="text-blue-400 hover:text-blue-300 font-medium transition-colors duration-200 text-sm lg:text-base xl:text-lg"
              >
                Criar nova conta
              </.link>
              <span class="text-gray-500 hidden sm:inline">|</span>
              <.link
                href={~p"/entrar"}
                class="text-blue-400 hover:text-blue-300 font-medium transition-colors duration-200 text-sm lg:text-base xl:text-lg"
              >
                Fazer login
              </.link>
            </div>
          </div>
          
    <!-- Features -->
          <div class="mt-8 lg:mt-12 xl:mt-16 grid grid-cols-3 gap-4 lg:gap-6 xl:gap-8 text-center">
            <div class="text-gray-400">
              <.icon
                name="hero-check-circle"
                class="w-6 h-6 lg:w-8 lg:h-8 xl:w-10 xl:h-10 mx-auto mb-2 text-blue-400"
              />
              <p class="text-xs lg:text-sm xl:text-base">Verificação</p>
            </div>
            <div class="text-gray-400">
              <.icon
                name="hero-shield-check"
                class="w-6 h-6 lg:w-8 lg:h-8 xl:w-10 xl:h-10 mx-auto mb-2 text-purple-400"
              />
              <p class="text-xs lg:text-sm xl:text-base">Segurança</p>
            </div>
            <div class="text-gray-400">
              <.icon
                name="hero-sparkles"
                class="w-6 h-6 lg:w-8 lg:h-8 xl:w-10 xl:h-10 mx-auto mb-2 text-pink-400"
              />
              <p class="text-xs lg:text-sm xl:text-base">Ativação</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <style>
      @keyframes blob {
        0% { transform: translate(0px, 0px) scale(1); }
        33% { transform: translate(30px, -50px) scale(1.1); }
        66% { transform: translate(-20px, 20px) scale(0.9); }
        100% { transform: translate(0px, 0px) scale(1); }
      }
      .animate-blob {
        animation: blob 7s infinite;
      }
      .animation-delay-2000 {
        animation-delay: 2s;
      }
      .animation-delay-4000 {
        animation-delay: 4s;
      }

      @keyframes logo {
        0% {
          transform: scale(1) rotate(0deg);
          box-shadow: 0 0 20px rgba(59, 130, 246, 0.5);
        }
        25% {
          transform: scale(1.05) rotate(2deg);
          box-shadow: 0 0 30px rgba(147, 51, 234, 0.6);
        }
        50% {
          transform: scale(1.1) rotate(0deg);
          box-shadow: 0 0 40px rgba(59, 130, 246, 0.7);
        }
        75% {
          transform: scale(1.05) rotate(-2deg);
          box-shadow: 0 0 30px rgba(147, 51, 234, 0.6);
        }
        100% {
          transform: scale(1) rotate(0deg);
          box-shadow: 0 0 20px rgba(59, 130, 246, 0.5);
        }
      }
      .animate-logo {
        animation: logo 3s ease-in-out infinite;
      }

      @keyframes text {
        0% {
          transform: scale(1);
          opacity: 0.8;
        }
        50% {
          transform: scale(1.1);
          opacity: 1;
        }
        100% {
          transform: scale(1);
          opacity: 0.8;
        }
      }
      .animate-text {
        animation: text 2s ease-in-out infinite;
        text-shadow: 0 0 10px rgba(255, 255, 255, 0.5);
      }
    </style>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Conta confirmada com sucesso.")
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "Link de confirmação é inválido ou expirou.")
             |> redirect(to: ~p"/")}
        end
    end
  end
end
