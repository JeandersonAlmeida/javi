defmodule JaviWeb.Components.UI.Button do
  use JaviWeb, :html

  @styles ["solid", "outline", "text", "ghost"]
  @colors ["dark", "white", "red", "blue", "yellow", "green", "purple"]
  @sizes ["2xs", "xs", "sm", "md", "lg", "xl", "w-full", "w-auto"]
  @rounded ["none", "sm", "md", "lg", "xl", "2xl", "3xl", "full"]

  attr :id, :string, required: true
  attr :type, :string, required: true
  attr :action_params, :map, default: %{}
  attr :link_params, :map, default: %{}
  attr :style, :string, default: "solid", values: @styles
  attr :color, :string, default: "blue", values: @colors
  attr :size, :string, default: "md", values: @sizes
  attr :rounded, :string, default: "md", values: @rounded
  attr :right_icon, :string, default: nil
  attr :left_icon, :string, default: nil
  attr :enabled, :boolean, default: true
  slot :inner_block

  def render(%{type: "action"} = assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      class={[build_button_colors(assigns), build_button_style(assigns), build_button_size(assigns)]}
      disabled={!@enabled}
      {@action_params}
    >
      <div class="flex items-center justify-center gap-x-1">
        <.icon
          :if={@left_icon}
          name={@left_icon}
          class={
            List.flatten([
              "flex-shrink-0 transition duration-75",
              build_icon_size(assigns),
              build_icon_classes(assigns)
            ])
          }
        />
        <span class="leading-none flex items-center">{render_slot(@inner_block)}</span>
        <.icon
          :if={@right_icon}
          name={@right_icon}
          class={
            List.flatten([
              "flex-shrink-0 transition duration-75",
              build_icon_size(assigns),
              build_icon_classes(assigns)
            ])
          }
        />
      </div>
    </button>
    """
  end

  def render(%{type: "submit"} = assigns) do
    ~H"""
    <button
      id={@id}
      type="submit"
      class={[build_button_colors(assigns), build_button_style(assigns), build_button_size(assigns)]}
      disabled={!@enabled}
      {@action_params}
    >
      <div class="flex items-center justify-center gap-x-1">
        <.icon
          :if={@left_icon}
          name={@left_icon}
          class={
            List.flatten([
              "flex-shrink-0 transition duration-75",
              build_icon_size(assigns),
              build_icon_classes(assigns)
            ])
          }
        />
        <span class="leading-none flex items-center">{render_slot(@inner_block)}</span>
        <.icon
          :if={@right_icon}
          name={@right_icon}
          class={
            List.flatten([
              "flex-shrink-0 transition duration-75",
              build_icon_size(assigns),
              build_icon_classes(assigns)
            ])
          }
        />
      </div>
    </button>
    """
  end

  def render(%{type: "link"} = assigns) do
    ~H"""
    <.link
      id={@id}
      class={[build_button_colors(assigns), build_button_style(assigns), build_button_size(assigns)]}
      {if @enabled, do: @link_params, else: %{navigate: ""}}
    >
      <div class="flex items-center justify-center gap-x-1 leading-none">
        <.icon
          :if={@left_icon}
          name={@left_icon}
          class={
            List.flatten([
              "flex-shrink-0 transition duration-75",
              build_icon_size(assigns),
              build_icon_classes(assigns)
            ])
          }
        />
        <span class="leading-none flex items-center">{render_slot(@inner_block)}</span>
        <.icon
          :if={@right_icon}
          name={@right_icon}
          class={
            List.flatten([
              "flex-shrink-0 transition duration-75",
              build_icon_size(assigns),
              build_icon_classes(assigns)
            ])
          }
        />
      </div>
    </.link>
    """
  end

  defp build_button_colors(%{style: "solid"} = assigns) do
    enabled_classes = %{
      "dark" =>
        "text-white bg-gray-900 hover:bg-black focus:ring-gray-300 dark:bg-gray-900 dark:hover:bg-gray-950",
      "white" =>
        "text-black bg-white hover:bg-gray-100 focus:ring-gray-300 dark:bg-gray-50 dark:hover:bg-gray-100",
      "red" =>
        "text-white bg-red-600 hover:bg-red-800 focus:ring-red-300 dark:bg-red-500 dark:hover:bg-red-700",
      "blue" =>
        "text-white bg-blue-500 hover:bg-blue-800 focus:ring-blue-300 dark:bg-blue-500 dark:hover:bg-blue-700",
      "yellow" =>
        "text-white bg-yellow-500 hover:bg-yellow-800 focus:ring-yellow-300 dark:bg-yellow-500 dark:hover:bg-yellow-700",
      "green" =>
        "text-white bg-green-600 hover:bg-green-800 focus:ring-green-300 dark:bg-green-500 dark:hover:bg-green-700",
      "purple" =>
        "text-white bg-purple-600 hover:bg-purple-800 focus:ring-purple-300 dark:bg-purple-500 dark:hover:bg-purple-700"
    }

    disabled_classes = %{
      "dark" =>
        "text-white bg-gray-900/25 hover:bg-black focus:ring-gray-300/25 dark:bg-gray-900/25 dark:hover:bg-gray-950/25",
      "white" =>
        "text-black bg-white/25 hover:bg-gray-100/25 focus:ring-gray-300/25 dark:bg-gray-50/25 dark:hover:bg-gray-100/25",
      "red" =>
        "text-white bg-red-600/25 hover:bg-red-800/25 focus:ring-red-300/25 dark:bg-red-500/25 dark:hover:bg-red-700/25",
      "blue" =>
        "text-white bg-blue-500/25 hover:bg-blue-800/25 focus:ring-blue-300/25 dark:bg-blue-500/25 dark:hover:bg-blue-700/25",
      "yellow" =>
        "text-white bg-yellow-500/25 hover:bg-yellow-800/25 focus:ring-yellow-300/25 dark:bg-yellow-500/25 dark:hover:bg-yellow-700/25",
      "green" =>
        "text-white bg-green-600/25 hover:bg-green-800/25 focus:ring-green-300/25 dark:bg-green-500/25 dark:hover:bg-green-700/25",
      "purple" =>
        "text-white bg-purple-600/25 hover:bg-purple-800/25 focus:ring-purple-300/25 dark:bg-purple-500/25 dark:hover:bg-purple-700/25"
    }

    [
      if(assigns.enabled,
        do: enabled_classes[assigns.color],
        else: disabled_classes[assigns.color]
      )
    ]
  end

  defp build_button_colors(%{style: "outline"} = assigns) do
    [
      assigns.color == "dark" and
        "text-gray-900 hover:text-white border-black hover:bg-gray-950 focus:ring-gray-600 dark:border-gray-800 dark:text-gray-800 dark:hover:bg-gray-500 dark:focus:ring-gray-700",
      assigns.color == "white" and
        "text-white hover:text-black border-white hover:bg-white focus:ring-gray-300 dark:border-white dark:text-white dark:hover:bg-gray-100 dark:focus:ring-gray-200",
      assigns.color == "red" and
        "text-red-600 hover:text-white border-red-600 hover:bg-red-600 focus:ring-red-300 dark:border-red-500 dark:text-red-500 dark:hover:bg-red-500 dark:focus:ring-red-800",
      assigns.color == "blue" and
        "text-blue-600 hover:text-white border-blue-600 hover:bg-blue-600 focus:ring-blue-300 dark:border-blue-500 dark:text-blue-500 dark:hover:bg-blue-500 dark:focus:ring-blue-800",
      assigns.color == "yellow" and
        "text-yellow-600 hover:text-white border-yellow-600 hover:bg-yellow-600 focus:ring-yellow-300 dark:border-yellow-500 dark:text-yellow-500 dark:hover:bg-yellow-500 dark:focus:ring-yellow-800",
      assigns.color == "green" and
        "text-green-600 hover:text-white border-green-600 hover:bg-green-600 focus:ring-green-300 dark:border-green-500 dark:text-green-500 dark:hover:bg-green-500 dark:focus:ring-green-800",
      assigns.color == "purple" and
        "text-purple-600 hover:text-white border-purple-600 hover:bg-purple-600 focus:ring-purple-300 dark:border-purple-500 dark:text-purple-500 dark:hover:bg-purple-500 dark:focus:ring-purple-800"
    ]
  end

  defp build_button_colors(%{style: "text"} = assigns) do
    [
      assigns.color == "dark" and
        "text-gray-900 dark:text-gray-800 hover:text-black",
      assigns.color == "white" and
        "text-white dark:text-white hover:text-gray-300",
      assigns.color == "red" and
        "text-red-600 dark:text-red-500 hover:text-red-800",
      assigns.color == "blue" and
        "text-blue-600 dark:text-blue-500 hover:text-blue-800",
      assigns.color == "yellow" and
        "text-yellow-600 dark:text-yellow-500 hover:text-yellow-800",
      assigns.color == "green" and
        "text-green-600 dark:text-green-500 hover:text-green-800",
      assigns.color == "purple" and
        "text-purple-600 dark:text-purple-500 hover:text-purple-800"
    ]
  end

  defp build_button_colors(%{style: "ghost"} = assigns) do
    enabled_classes = %{
      "dark" =>
        "text-gray-600 bg-gray-200/70 hover:bg-black hover:text-gray-200 focus:ring-gray-300 dark:bg-gray-900 dark:hover:bg-gray-400",
      "white" =>
        "text-gray-900 bg-white hover:bg-gray-200 focus:ring-gray-400 dark:bg-gray-100 dark:hover:bg-gray-200",
      "red" =>
        "text-red-600 bg-red-100/70 hover:bg-red-200/50 focus:ring-red-300 dark:bg-red-300 dark:hover:bg-red-400",
      "blue" =>
        "text-blue-600 bg-blue-100/70 hover:bg-blue-200/50 focus:ring-blue-300 dark:bg-blue-300 dark:hover:bg-blue-400",
      "yellow" =>
        "text-yellow-600 bg-yellow-100/70 hover:bg-yellow-200/50 focus:ring-yellow-300 dark:bg-yellow-300 dark:hover:bg-yellow-400",
      "green" =>
        "text-green-600 bg-green-100/70 hover:bg-green-200/50 focus:ring-green-300 dark:bg-green-300 dark:hover:bg-green-400",
      "purple" =>
        "text-purple-600 bg-purple-100/70 hover:bg-purple-200/50 focus:ring-purple-300 dark:bg-purple-300 dark:hover:bg-purple-400"
    }

    disabled_classes = %{
      "dark" =>
        "text-gray-300 bg-gray-200/25 hover:bg-gray-300 hover:text-gray-400 focus:ring-gray-300/25 dark:bg-gray-300/25 dark:hover:bg-gray-900/25",
      "white" =>
        "text-gray-300 bg-white/30 hover:bg-gray-100/25 focus:ring-gray-300/25 dark:bg-gray-50/25 dark:hover:bg-gray-100/25",
      "red" =>
        "text-red-300 bg-red-100/25 hover:bg-red-200/25 focus:ring-red-300/25 dark:3g-red-500/25 dark:4over:bg-red-700/25",
      "blue" =>
        "text-blue-300 bg-blue-100/25 hover:bg-blue-200/25 focus:ring-blue-300/25 dark:3g-blue-500/25 dark:4over:bg-blue-700/25",
      "yellow" =>
        "text-yellow-300 bg-yellow-100/25 hover:bg-yellow-200/25 focus:ring-yellow-300/25 dark:3g-yellow-500/25 dark:4over:bg-yellow-700/25",
      "green" =>
        "text-green-300 bg-green-100/25 hover:bg-green-200/25 focus:ring-green-300/25 dark:3g-green-500/25 dark:4over:bg-green-700/25",
      "purple" =>
        "text-purple-300 bg-purple-100/25 hover:bg-purple-200/25 focus:ring-purple-300/25 dark:3g-purple-500/25 dark:4over:bg-purple-700/25"
    }

    [
      if(assigns.enabled,
        do: enabled_classes[assigns.color],
        else: disabled_classes[assigns.color]
      )
    ]
  end

  defp build_button_style(assigns) do
    [
      "inline-block group/style rounded-#{assigns.rounded}",
      assigns.style == "solid" and
        "text-center focus:ring-4 focus:outline-none uppercase font-semibold",
      assigns.style == "ghost" and
        "text-center focus:ring-4 focus:outline-none uppercase font-normal",
      assigns.style == "outline" and
        "text-center border border-2 focus:ring-4 focus:outline-none dark:hover:text-white uppercase font-semibold",
      assigns.style == "text" and
        "focus:outline-none font-semibold",
      assigns.enabled or "cursor-not-allowed"
    ]
  end

  defp build_icon_classes(%{style: "solid"} = assigns) do
    [
      assigns.color == "dark" and "text-white group-hover/style:text-white",
      assigns.color == "white" and "text-black group-hover/style:text-black",
      assigns.color == "red" and "text-white group-hover/style:text-white",
      assigns.color == "blue" and "text-white group-hover/style:text-white",
      assigns.color == "yellow" and "text-white group-hover/style:text-white",
      assigns.color == "green" and "text-white group-hover/style:text-white",
      assigns.color == "purple" and "text-white group-hover/style:text-white"
    ]
  end

  defp build_icon_classes(%{style: "ghost"} = assigns) do
    enabled_classes = %{
      "dark" => "text-dark-600 group-hover/style:text-dark-700",
      "white" => "text-white-600 group-hover/style:text-white-700",
      "red" => "text-red-600 group-hover/style:text-red-700",
      "blue" => "text-blue-600 group-hover/style:text-blue-700",
      "yellow" => "text-yellow-600 group-hover/style:text-yellow-700",
      "green" => "text-green-600 group-hover/style:text-green-700",
      "purple" => "text-purple-600 group-hover/style:text-purple-700"
    }

    disabled_classes = %{
      "dark" => "text-dark-300 group-hover/style:text-dark-200",
      "white" => "text-white-300 group-hover/style:text-white-200",
      "red" => "text-red-300 group-hover/style:text-red-200",
      "blue" => "text-blue-300 group-hover/style:text-blue-200",
      "yellow" => "text-yellow-300 group-hover/style:text-yellow-200",
      "green" => "text-green-300 group-hover/style:text-green-200",
      "purple" => "text-purple-300 group-hover/style:text-purple-200"
    }

    [
      if(assigns.enabled,
        do: enabled_classes[assigns.color],
        else: disabled_classes[assigns.color]
      )
    ]
  end

  defp build_icon_classes(%{style: "outline"} = assigns) do
    [
      assigns.color == "dark" and "text-gray-950 group-hover/style:text-white",
      assigns.color == "white" and "text-white group-hover/style:text-black",
      assigns.color == "red" and "text-red-600 group-hover/style:text-white",
      assigns.color == "blue" and "text-blue-500 group-hover/style:text-white",
      assigns.color == "yellow" and "text-yellow-500 group-hover/style:text-white",
      assigns.color == "green" and "text-green-600 group-hover/style:text-white",
      assigns.color == "purple" and "text-purple-600 group-hover/style:text-white"
    ]
  end

  defp build_icon_classes(%{style: "text"} = assigns) do
    [
      assigns.color == "dark" and "text-gray-900 group-hover/style:text-black",
      assigns.color == "white" and "text-white group-hover/style:text-gray-300",
      assigns.color == "red" and "text-red-600 group-hover/style:text-red-800",
      assigns.color == "blue" and "text-blue-600 group-hover/style:text-blue-800",
      assigns.color == "yellow" and "text-yellow-600 group-hover/style:text-yellow-800",
      assigns.color == "green" and "text-green-600 group-hover/style:text-green-800",
      assigns.color == "purple" and "text-purple-600 group-hover/style:text-purple-800"
    ]
  end

  defp build_icon_size(assigns) do
    [
      assigns.size == "2xs" and "w-4 h-4",
      assigns.size == "xs" and "w-4 h-4",
      assigns.size == "sm" and "w-4 h-4",
      assigns.size == "md" and "w-6 h-6",
      assigns.size == "lg" and "w-6 h-6",
      assigns.size == "xlg" and "w-7 h-7",
      assigns.size == "w-full" and "w-7 h-7",
      assigns.size == "w-auto" and "w-6 h-6"
    ]
  end

  defp build_button_size(assigns) do
    [
      assigns.size == "2xs" and "p-0.5 text-xs",
      assigns.size == "xs" and "p-1.5 text-xs",
      assigns.size == "sm" and "px-3 py-2 text-sm",
      assigns.size == "md" and "px-4 py-2 text-sm",
      assigns.size == "lg" and "px-5 py-3 text-base",
      assigns.size == "xlg" and "px-6 py-3.5 text-base",
      assigns.size == "w-full" and "px-6 py-3.5 text-base w-full",
      assigns.size == "w-auto" and "px-6 py-3.5 text-base w-auto"
    ]
  end
end
