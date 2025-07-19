defmodule JaviWeb.UserLoginLive do
  use JaviWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen flex-col bg-[#141414] dark justify-between group/design-root overflow-hidden">
      <div>
        <div
          class="w-full bg-center bg-no-repeat bg-cover flex flex-col justify-end overflow-hidden bg-[#141414] rounded-lg h-[450px] lg:h-80"
          style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuD9gZbtm0ReQ-_8-3zd_zWooPEjBCv926WXbtXxMTuSo36AUJlSWjOv36RVhfBaIT4RIYC4hA08tnMdi-wALYt3VDgE5xs1XhnNcaVT2AdDsDl76SlPT1pI3TrUxOybUXTj5TuaTEfYgcQU8gjBwg9qMtHOH09URNO8RQd1BRw5rkuW7ykX7TOIvfSe_kLuGrFv1h05R0cMvXfpeM2kgNnTNiFOwJbs_jkL7BpLgVcCFqWWeuFrY7XajBQbn7YNTUJbVwdtiyHX_zw3");'
        >
        </div>

        <h1 class="my-3 text-white text-5xl font-bold leading-tight tracking-[-0.015em] text-center">
          Entrar
        </h1>
        <.form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
          <div class="flex flex-col max-w-[480px] gap-y-2 px-6 py-3 mx-auto">
            <label class="flex flex-col min-w-40 flex-1">
              <PetalComponents.Form.email_input
                form={@form}
                field={:email}
                class="form-input flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-white focus:outline-0 focus:ring-0 border-none bg-[#303030] h-14 placeholder:text-[#ababab] p-4 text-base"
                label="Email"
                placeholder="Email"
              />
            </label>
            <label class="flex flex-col min-w-40 flex-1">
              <PetalComponents.Form.password_input
                form={@form}
                field={:password}
                placeholder="Senha"
                class="form-input flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-white focus:outline-0 focus:ring-0 border-none bg-[#303030] h-14 placeholder:text-[#ababab] p-4 text-base"
              />
            </label>
          </div>
          <label class="flex w-max mx-auto items-center gap-x-2 cursor-pointer">
            <PetalComponents.Form.checkbox
              form={@form}
              field={:remember_me}
              class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded-sm focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
            />
            <span class="text-[#ababab] text-sm leading-normal">
              Manter-se conectado
            </span>
          </label>

          <div class="px-6 py-3 max-w-[480px] mx-auto">
            <button
              type="submit"
              class="flex min-w-[84px] w-full cursor-pointer items-center justify-center overflow-hidden rounded-lg h-12 px-5 bg-gradient-to-r from-sky-400 to-blue-500 text-white text-base font-bold tracking-[0.015em]"
            >
              <span class="truncate">Entrar</span>
            </button>
          </div>
        </.form>
      </div>
      <div class="flex self-end gap-x-2 justify-center mx-auto pb-6">
        <.link href={~p"/users/reset_password"}>
          <span class="text-gray-500 underline">
            Esqueceu sua senha?
          </span>
        </.link>
        <span class="text-white">|</span>
        <.link href={~p"/users/register"}>
          <span class="text-gray-500 underline">
            Cadastre-se
          </span>
        </.link>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
