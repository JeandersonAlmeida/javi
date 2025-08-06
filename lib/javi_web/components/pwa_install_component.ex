defmodule JaviWeb.PWAInstallComponent do
  use Phoenix.Component

  def pwa_install_button(assigns) do
    ~H"""
    <div id="pwa-install-container" class="hidden">
      <button
        id="pwa-install-btn"
        class="fixed top-4 right-4 bg-gradient-to-r from-purple-600 to-pink-600 text-white px-4 py-3 rounded-full shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-300 z-50 flex items-center space-x-2"
        phx-click="install_pwa"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"
          >
          </path>
        </svg>
        <span>Install App</span>
      </button>
    </div>
    """
  end

  def pwa_status(assigns) do
    ~H"""
    <div class="text-sm text-gray-400">
      <div class="flex items-center space-x-2">
        <div class="w-2 h-2 rounded-full bg-green-500"></div>
        <span>PWA Ready</span>
      </div>
    </div>
    """
  end
end
