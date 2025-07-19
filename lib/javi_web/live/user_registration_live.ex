defmodule JaviWeb.UserRegistrationLive do
  use JaviWeb, :live_view

  alias Javi.Accounts
  alias Javi.Accounts.User

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
          Criar conta
        </h1>
        <.form
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log_in?_action=registered"}
          method="post"
          for={@form}
        >
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
          <div class="px-6 py-3 max-w-[480px] mx-auto">
            <button
              type="submit"
              class="flex min-w-[84px] w-full cursor-pointer items-center justify-center overflow-hidden rounded-lg h-12 px-5 bg-gradient-to-r from-blue-800 to-indigo-900 text-white text-base font-bold tracking-[0.015em]"
            >
              <span class="truncate">Criar conta</span>
            </button>
          </div>
          <div class="flex gap-x-2 justify-center mx-auto pt-4">
            <span class="text-gray-500">
              Já está cadastrado?
            </span>
            <.link href={~p"/users/log_in"}>
              <span class="text-gray-400 underline">
                Entre na conta
              </span>
            </.link>
          </div>
        </.form>
      </div>
      <.error :if={@check_errors}>
        Oops, something went wrong! Please check the errors below.
      </.error>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
