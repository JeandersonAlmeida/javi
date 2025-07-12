defmodule JaviWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use JaviWeb, :controller` and
  `use JaviWeb, :live_view`.
  """
  use JaviWeb, :html

  embed_templates "layouts/*"
end
