defmodule JaviWeb.PWA do
  @moduledoc """
  PWA (Progressive Web App) configuration and utilities.
  """

  @doc """
  Returns the PWA manifest URL.
  """
  def manifest_url, do: "/manifest.json"

  @doc """
  Returns the service worker URL.
  """
  def service_worker_url, do: "/sw.js"

  @doc """
  Returns the PWA script URL.
  """
  def pwa_script_url, do: "/pwa.js"

  @doc """
  Returns the theme color for the PWA.
  """
  def theme_color, do: "#8b5cf6"

  @doc """
  Returns the background color for the PWA.
  """
  def background_color, do: "#0f172a"

  @doc """
  Returns the app name for the PWA.
  """
  def app_name, do: "Javi"

  @doc """
  Returns the app short name for the PWA.
  """
  def app_short_name, do: "Javi"

  @doc """
  Returns the app description for the PWA.
  """
  def app_description do
    "Track your watchlist, discover new content, and never lose track of what you want to watch next. Your personal entertainment companion."
  end

  @doc """
  Returns the app start URL for the PWA.
  """
  def start_url, do: "/"

  @doc """
  Returns the app display mode for the PWA.
  """
  def display_mode, do: "standalone"

  @doc """
  Returns the app orientation for the PWA.
  """
  def orientation, do: "portrait-primary"

  @doc """
  Returns the app scope for the PWA.
  """
  def scope, do: "/"

  @doc """
  Returns the app language for the PWA.
  """
  def language, do: "en"

  @doc """
  Returns the app categories for the PWA.
  """
  def categories, do: ["entertainment", "productivity", "lifestyle"]

  @doc """
  Returns the icon sizes for the PWA.
  """
  def icon_sizes do
    [
      %{
        src: "/images/icon-72x72.png",
        sizes: "72x72",
        type: "image/png",
        purpose: "maskable any"
      },
      %{
        src: "/images/icon-96x96.png",
        sizes: "96x96",
        type: "image/png",
        purpose: "maskable any"
      },
      %{
        src: "/images/icon-128x128.png",
        sizes: "128x128",
        type: "image/png",
        purpose: "maskable any"
      },
      %{
        src: "/images/icon-144x144.png",
        sizes: "144x144",
        type: "image/png",
        purpose: "maskable any"
      },
      %{
        src: "/images/icon-152x152.png",
        sizes: "152x152",
        type: "image/png",
        purpose: "maskable any"
      },
      %{
        src: "/images/icon-192x192.png",
        sizes: "192x192",
        type: "image/png",
        purpose: "maskable any"
      },
      %{
        src: "/images/icon-384x384.png",
        sizes: "384x384",
        type: "image/png",
        purpose: "maskable any"
      },
      %{
        src: "/images/icon-512x512.png",
        sizes: "512x512",
        type: "image/png",
        purpose: "maskable any"
      }
    ]
  end

  @doc """
  Returns the app shortcuts for the PWA.
  """
  def shortcuts do
    [
      %{
        name: "Dashboard",
        short_name: "Dashboard",
        description: "View your dashboard",
        url: "/home",
        icons: [%{src: "/images/icon-96x96.png", sizes: "96x96"}]
      },
      %{
        name: "Search",
        short_name: "Search",
        description: "Search for movies and shows",
        url: "/search",
        icons: [%{src: "/images/icon-96x96.png", sizes: "96x96"}]
      },
      %{
        name: "My Lists",
        short_name: "Lists",
        description: "View your watchlists",
        url: "/lists",
        icons: [%{src: "/images/icon-96x96.png", sizes: "96x96"}]
      }
    ]
  end

  @doc """
  Returns the app screenshots for the PWA.
  """
  def screenshots do
    [
      %{
        src: "/images/screenshot-wide.png",
        sizes: "1280x720",
        type: "image/png",
        form_factor: "wide"
      },
      %{
        src: "/images/screenshot-narrow.png",
        sizes: "750x1334",
        type: "image/png",
        form_factor: "narrow"
      }
    ]
  end

  @doc """
  Returns the complete PWA manifest as a map.
  """
  def manifest do
    %{
      name: app_name(),
      short_name: app_short_name(),
      description: app_description(),
      start_url: start_url(),
      display: display_mode(),
      background_color: background_color(),
      theme_color: theme_color(),
      orientation: orientation(),
      scope: scope(),
      lang: language(),
      categories: categories(),
      icons: icon_sizes(),
      shortcuts: shortcuts(),
      screenshots: screenshots()
    }
  end

  @doc """
  Returns the PWA meta tags for the HTML head.
  """
  def meta_tags do
    [
      %{name: "theme-color", content: theme_color()},
      %{name: "apple-mobile-web-app-capable", content: "yes"},
      %{name: "apple-mobile-web-app-status-bar-style", content: "default"},
      %{name: "apple-mobile-web-app-title", content: app_name()},
      %{name: "mobile-web-app-capable", content: "yes"},
      %{name: "application-name", content: app_name()},
      %{name: "msapplication-TileColor", content: theme_color()},
      %{name: "msapplication-tap-highlight", content: "no"}
    ]
  end

  @doc """
  Returns the PWA link tags for the HTML head.
  """
  def link_tags do
    [
      %{rel: "manifest", href: manifest_url()},
      %{rel: "apple-touch-icon", href: "/images/icon-152x152.png"},
      %{rel: "apple-touch-icon", sizes: "152x152", href: "/images/icon-152x152.png"},
      %{rel: "apple-touch-icon", sizes: "180x180", href: "/images/icon-180x180.png"},
      %{rel: "apple-touch-icon", sizes: "167x167", href: "/images/icon-167x167.png"}
    ]
  end
end
