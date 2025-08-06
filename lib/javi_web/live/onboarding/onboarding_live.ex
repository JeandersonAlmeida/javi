defmodule JaviWeb.Onboarding.OnboardingLive do
  use JaviWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_step, 0)
      |> assign(:total_steps, 6)
      |> assign(:onboarding_data, get_onboarding_data())
      |> assign(:show_onboarding, true)
      |> assign(:pwa_installable, false)
      |> assign(:pwa_installed, false)
      # Auto-play soundtrack
      |> assign(:audio_playing, true)

    {:ok, socket}
  end

  @impl true
  def handle_event("next_step", _params, socket) do
    current_step = socket.assigns.current_step
    total_steps = socket.assigns.total_steps

    if current_step < total_steps - 1 do
      {:noreply, assign(socket, :current_step, current_step + 1)}
    else
      # Mark onboarding as completed
      user = socket.assigns.current_user

      if user do
        user
        |> Javi.Accounts.User.complete_onboarding_changeset()
        |> Javi.Repo.update()
      end

      {:noreply, push_navigate(socket, to: ~p"/inicio")}
    end
  end

  @impl true
  def handle_event("previous_step", _params, socket) do
    current_step = socket.assigns.current_step

    if current_step > 0 do
      {:noreply, assign(socket, :current_step, current_step - 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("skip_onboarding", _params, socket) do
    # Mark onboarding as completed even when skipped
    user = socket.assigns.current_user

    if user do
      user
      |> Javi.Accounts.User.complete_onboarding_changeset()
      |> Javi.Repo.update()
    end

    {:noreply, push_navigate(socket, to: ~p"/inicio")}
  end

  @impl true
  def handle_event("go_to_step", %{"step" => step}, socket) do
    step_number = String.to_integer(step)
    {:noreply, assign(socket, :current_step, step_number)}
  end

  @impl true
  def handle_event("toggle_audio", _params, socket) do
    audio_playing = !socket.assigns.audio_playing
    {:noreply, assign(socket, :audio_playing, audio_playing)}
  end

  def handle_event("pwa_installable", %{"installable" => installable}, socket) do
    {:noreply, assign(socket, :pwa_installable, installable == "true")}
  end

  def handle_event("pwa_installed", _params, socket) do
    {:noreply, assign(socket, :pwa_installed, true)}
  end

  def handle_event("skip_pwa_install", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/inicio")}
  end

  @impl true
  def handle_event("object_click", %{"object" => object}, socket) do
    # Handle different object interactions
    case object do
      "floater1" ->
        {:noreply, put_flash(socket, :info, "🟢 Floating object 1 clicked!")}

      "floater2" ->
        {:noreply, put_flash(socket, :info, "🟣 Floating object 2 clicked!")}

      "bouncer" ->
        {:noreply, put_flash(socket, :info, "🟡 Bouncing object clicked!")}

      "spinner" ->
        {:noreply, put_flash(socket, :info, "🔄 Spinning object clicked!")}

      "pulser" ->
        {:noreply, put_flash(socket, :info, "💜 Pulsing object clicked!")}

      "floater3" ->
        {:noreply, put_flash(socket, :info, "🔵 Floating object 3 clicked!")}

      "new1" ->
        {:noreply, put_flash(socket, :info, "🟢 New object 1 clicked!")}

      "new2" ->
        {:noreply, put_flash(socket, :info, "🌹 New object 2 clicked!")}

      "new3" ->
        {:noreply, put_flash(socket, :info, "🔵 New object 3 clicked!")}

      "new4" ->
        {:noreply, put_flash(socket, :info, "🟠 New object 4 clicked!")}

      "new5" ->
        {:noreply, put_flash(socket, :info, "🔷 New object 5 clicked!")}

      "new6" ->
        {:noreply, put_flash(socket, :info, "🟣 New object 6 clicked!")}

      "new7" ->
        {:noreply, put_flash(socket, :info, "🟢 New object 7 clicked!")}

      "new8" ->
        {:noreply, put_flash(socket, :info, "🌸 New object 8 clicked!")}

      "new9" ->
        {:noreply, put_flash(socket, :info, "🟡 New object 9 clicked!")}

      "new10" ->
        {:noreply, put_flash(socket, :info, "🔵 New object 10 clicked!")}

      _ ->
        {:noreply, socket}
    end
  end

  defp get_onboarding_data do
    [
      %{
        id: 1,
        title: "Bem-vindo ao Javi",
        subtitle: "Sua plataforma completa para organizar filmes e séries",
        description: "",
        # Avatar
        image: "https://image.tmdb.org/t/p/original/1E5baAaEse26fej7uHcjOgEE2t2.jpg",
        bg_color: "from-cyan-600 to-blue-600",
        overlay_title: "Descubra o Cinema",
        overlay_subtitle: "Sua jornada começa aqui"
      },
      %{
        id: 2,
        title: "Explore Milhares de Títulos",
        subtitle: "Encontre o que assistir com nossa vasta biblioteca",
        description: "",
        # The Matrix
        image: "https://image.tmdb.org/t/p/original/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg",
        bg_color: "from-green-600 to-emerald-600",
        overlay_title: "Explore Sem Limites",
        overlay_subtitle: "Milhares de títulos à sua disposição"
      },
      %{
        id: 3,
        title: "Organize Suas Listas",
        subtitle: "Crie listas personalizadas para seus favoritos",
        description: "",
        # The Dark Knight
        image: "https://image.tmdb.org/t/p/original/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
        bg_color: "from-purple-600 to-pink-600",
        overlay_title: "Organize Seu Mundo",
        overlay_subtitle: "Crie suas listas personalizadas"
      },
      %{
        id: 4,
        title: "Avalie e Comente",
        subtitle: "Compartilhe suas opiniões sobre os títulos",
        description: "",
        # The Godfather
        image: "https://image.tmdb.org/t/p/original/3bhkrj58Vtu7enYsRolD1fZdja1.jpg",
        bg_color: "from-orange-600 to-red-600",
        overlay_title: "Compartilhe Suas Opiniões",
        overlay_subtitle: "Avalie e descubra novos títulos"
      },
      %{
        id: 5,
        title: "Pronto para Começar?",
        subtitle: "Sua jornada cinematográfica está prestes a começar",
        description: "",
        image: "https://image.tmdb.org/t/p/original/u3bZgnGQ9T01sWNhyveQz0wH0Hl.jpg",
        bg_color: "from-yellow-600 to-orange-600",
        overlay_title: "Sua Jornada Começa",
        overlay_subtitle: "Explore o mundo do cinema"
      },
      %{
        id: 6,
        title: "Instale o App",
        subtitle: "Tenha o Javi sempre à mão no seu dispositivo",
        description: "Instale o app para acesso rápido e funcionalidades offline",
        image: "https://image.tmdb.org/t/p/original/1E5baAaEse26fej7uHcjOgEE2t2.jpg",
        bg_color: "from-purple-600 to-pink-600",
        overlay_title: "App Instalável",
        overlay_subtitle: "Acesse de qualquer lugar"
      }
    ]
  end
end
