defmodule JaviWeb.Components.BottomNavigation do
  use JaviWeb, :html
  import JaviWeb.CoreComponents, only: [icon: 1]

  def bottom_navigation(assigns) do
    ~H"""
    <!-- Mobile Bottom Navigation -->
    <div class="bottom-navigation-fixed fixed bottom-0 left-0 right-0 z-50 bg-[#212121] lg:hidden">
      <div class="flex gap-2 border-t border-[#303030] bg-[#212121] px-4 py-2">
        <.link
          navigate={~p"/inicio"}
          class={"just flex flex-1 flex-col items-center justify-end gap-1 #{if @current_page == :home, do: "text-white", else: "text-[#ababab]"}"}
        >
          <div class={"#{if @current_page == :home, do: "text-white", else: "text-[#ababab]"} flex h-8 items-center justify-center"}>
            <.icon
              name={if @current_page == :home, do: "hero-home-solid", else: "hero-home"}
              class="w-6 h-6"
            />
          </div>
          <p class={"#{if @current_page == :home, do: "text-white", else: "text-[#ababab]"} text-xs font-medium leading-normal tracking-[0.015em]"}>
            Início
          </p>
        </.link>

        <.link
          navigate={~p"/pesquisar"}
          class={"just flex flex-1 flex-col items-center justify-end gap-1 #{if @current_page == :search, do: "text-white", else: "text-[#ababab]"}"}
        >
          <div class={"#{if @current_page == :search, do: "text-white", else: "text-[#ababab]"} flex h-8 items-center justify-center"}>
            <.icon
              name={
                if @current_page == :search,
                  do: "hero-magnifying-glass-solid",
                  else: "hero-magnifying-glass"
              }
              class="w-6 h-6"
            />
          </div>
          <p class={"#{if @current_page == :search, do: "text-white", else: "text-[#ababab]"} text-xs font-medium leading-normal tracking-[0.015em]"}>
            Pesquisar
          </p>
        </.link>

        <.link
          navigate={~p"/listas"}
          class={"just flex flex-1 flex-col items-center justify-end gap-1 #{if @current_page == :media, do: "text-white", else: "text-[#ababab]"}"}
        >
          <div class={"#{if @current_page == :media, do: "text-white", else: "text-[#ababab]"} flex h-8 items-center justify-center"}>
            <.icon
              name={
                if @current_page == :media,
                  do: "hero-rectangle-stack-solid",
                  else: "hero-rectangle-stack"
              }
              class="w-6 h-6"
            />
          </div>
          <p class={"#{if @current_page == :media, do: "text-white", else: "text-[#ababab]"} text-xs font-medium leading-normal tracking-[0.015em]"}>
            Listas
          </p>
        </.link>

        <.link
          navigate={~p"/perfil"}
          class={"just flex flex-1 flex-col items-center justify-end gap-1 #{if @current_page == :profile, do: "text-white", else: "text-[#ababab]"}"}
        >
          <div class={"#{if @current_page == :profile, do: "text-white", else: "text-[#ababab]"} flex h-8 items-center justify-center"}>
            <.icon
              name={if @current_page == :profile, do: "hero-user-solid", else: "hero-user"}
              class="w-6 h-6"
            />
          </div>
          <p class={"#{if @current_page == :profile, do: "text-white", else: "text-[#ababab]"} text-xs font-medium leading-normal tracking-[0.015em]"}>
            Perfil
          </p>
        </.link>
        <.link
          navigate={~p"/amigos"}
          class={"just flex flex-1 flex-col items-center justify-end gap-1 #{if @current_page == :friends, do: "text-white", else: "text-[#ababab]"}"}
        >
          <div class={"#{if @current_page == :friends, do: "text-white", else: "text-[#ababab]"} relative flex h-8 items-center justify-center"}>
            <.icon
              name={
                if @current_page == :friends, do: "hero-user-group-solid", else: "hero-user-group"
              }
              class="w-6 h-6"
            />
            <span
              :if={assigns[:pending_count] && @pending_count > 0}
              class="absolute -top-1 -right-2 bg-red-600 text-white text-[10px] leading-none px-1.5 py-0.5 rounded-full"
            >
              {@pending_count}
            </span>
          </div>
          <p class={"#{if @current_page == :friends, do: "text-white", else: "text-[#ababab]"} text-xs font-medium leading-normal tracking-[0.015em]"}>
            Amigos
          </p>
        </.link>
      </div>
    </div>

    <!-- Desktop Side Navigation -->
    <div class="hidden lg:flex fixed left-0 top-0 bottom-0 z-50 bg-[#1a1a1a] border-r border-[#303030] w-64">
      <div class="flex flex-col w-full">
        <!-- Logo/Brand Area -->
        <div class="flex items-center justify-center h-16 border-b border-[#303030]">
          <h1 class="text-white text-xl font-bold">Javi</h1>
        </div>
        
    <!-- Navigation Items -->
        <nav class="flex-1 px-4 py-6 space-y-2">
          <.link
            navigate={~p"/inicio"}
            class={"flex items-center gap-4 px-4 py-3 rounded-lg transition-all duration-200 hover:bg-[#2a2a2a] #{if @current_page == :home, do: "bg-[#2a2a2a] text-white", else: "text-[#ababab] hover:text-white"}"}
          >
            <.icon
              name={if @current_page == :home, do: "hero-home-solid", else: "hero-home"}
              class="w-6 h-6"
            />
            <span class="font-medium">Início</span>
          </.link>

          <.link
            navigate={~p"/pesquisar"}
            class={"flex items-center gap-4 px-4 py-3 rounded-lg transition-all duration-200 hover:bg-[#2a2a2a] #{if @current_page == :search, do: "bg-[#2a2a2a] text-white", else: "text-[#ababab] hover:text-white"}"}
          >
            <.icon
              name={
                if @current_page == :search,
                  do: "hero-magnifying-glass-solid",
                  else: "hero-magnifying-glass"
              }
              class="w-6 h-6"
            />
            <span class="font-medium">Pesquisar</span>
          </.link>

          <.link
            navigate={~p"/listas"}
            class={"flex items-center gap-4 px-4 py-3 rounded-lg transition-all duration-200 hover:bg-[#2a2a2a] #{if @current_page == :media, do: "bg-[#2a2a2a] text-white", else: "text-[#ababab] hover:text-white"}"}
          >
            <.icon
              name={
                if @current_page == :media,
                  do: "hero-rectangle-stack-solid",
                  else: "hero-rectangle-stack"
              }
              class="w-6 h-6"
            />
            <span class="font-medium">Listas</span>
          </.link>

          <.link
            navigate={~p"/perfil"}
            class={"flex items-center gap-4 px-4 py-3 rounded-lg transition-all duration-200 hover:bg-[#2a2a2a] #{if @current_page == :profile, do: "bg-[#2a2a2a] text-white", else: "text-[#ababab] hover:text-white"}"}
          >
            <.icon
              name={if @current_page == :profile, do: "hero-user-solid", else: "hero-user"}
              class="w-6 h-6"
            />
            <span class="font-medium">Perfil</span>
          </.link>
          <.link
            navigate={~p"/amigos"}
            class={"flex items-center gap-4 px-4 py-3 rounded-lg transition-all duration-200 hover:bg-[#2a2a2a] #{if @current_page == :friends, do: "bg-[#2a2a2a] text-white", else: "text-[#ababab] hover:text-white"}"}
          >
            <div class="relative">
              <.icon
                name={
                  if @current_page == :friends, do: "hero-user-group-solid", else: "hero-user-group"
                }
                class="w-6 h-6"
              />
              <span
                :if={assigns[:pending_count] && @pending_count > 0}
                class="absolute -top-1 -right-2 bg-red-600 text-white text-[10px] leading-none px-1.5 py-0.5 rounded-full"
              >
                {@pending_count}
              </span>
            </div>
            <span class="font-medium">Amigos</span>
          </.link>
        </nav>
        
    <!-- Bottom Section (could be used for user info or settings) -->
        <div class="border-t border-[#303030] p-4">
          <div class="flex items-center gap-3 px-4 py-2 rounded-lg bg-[#2a2a2a]">
            <.icon name="hero-cog-6-tooth" class="w-5 h-5 text-[#ababab]" />
            <span class="text-[#ababab] text-sm font-medium">Configurações</span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
