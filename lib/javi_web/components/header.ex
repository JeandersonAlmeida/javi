defmodule JaviWeb.Components.Header do
  use JaviWeb, :html
  import JaviWeb.CoreComponents, only: [icon: 1]

  attr :title, :string, default: nil
  attr :show_back, :boolean, default: false
  attr :on_back, :string, default: "go_back"
  attr :right_click, :string, default: nil
  attr :right_icon, :string, default: nil
  attr :class, :string, default: nil
  attr :border, :boolean, default: true
  attr :ml_for_sidebar, :boolean, default: true

  slot :right
  slot :bottom
  slot :inner_block

  def top_header(assigns) do
    ~H"""
    <div class={[
      "fixed top-0 left-0 right-0 z-50 bg-[#141414]",
      @ml_for_sidebar && "lg:ml-64",
      @border && "border-b border-[#303030]",
      @class
    ]}>
      <div class="flex items-center bg-[#141414] p-4 justify-between">
        <%= if @show_back do %>
          <button
            phx-click={@on_back}
            class="text-white flex size-12 shrink-0 items-center"
            data-icon="ArrowLeft"
            data-size="24px"
            data-weight="regular"
          >
            <.icon name="hero-arrow-left" class="w-6 h-6" />
          </button>
        <% else %>
          <div class="w-12"></div>
        <% end %>

        <h2 class="text-white text-lg lg:text-xl font-bold leading-tight tracking-[-0.015em] flex-1 text-center">
          <%= if @title do %>
            {@title}
          <% else %>
            {render_slot(@inner_block)}
          <% end %>
        </h2>

        <%= if @right != [] do %>
          <div class="flex items-center justify-end">
            {render_slot(@right)}
          </div>
        <% else %>
          <%= if @right_icon && @right_click do %>
            <button phx-click={@right_click} class="text-white flex size-12 shrink-0 items-center">
              <.icon name={@right_icon} class="w-6 h-6" />
            </button>
          <% else %>
            <div class="w-12"></div>
          <% end %>
        <% end %>
      </div>

      <div :if={@bottom != []}>
        {render_slot(@bottom)}
      </div>
    </div>
    """
  end
end
