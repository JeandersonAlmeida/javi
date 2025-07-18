defmodule JaviWeb.Components.UI.ButtonTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  alias JaviWeb.Components.UI.Button

  describe "Button component" do
    test "render inner block" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.render id="button" type="action">
          <span class="inner">Inner content</span>
        </Button.render>
        """)

      inner =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s|span.inner|)

      assert Floki.text(inner) =~ "Inner content"
    end

    test "render action button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.render
          id="button"
          type="action"
          action_params={%{"phx-click" => "action-test", "phx-value-action-param" => "action-param"}}
        >
          Action button
        </Button.render>
        """)

      item =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s|button[phx-click="action-test"][phx-value-action-param="action-param"]|)

      assert Floki.text(item) =~ "Action button"
    end

    test "render submit button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.render id="button" type="submit" action_params={%{"phx-submit" => "action-test"}}>
          Submit button
        </Button.render>
        """)

      item =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s|button[phx-submit="action-test"]|)

      assert Floki.text(item) =~ "Submit button"
    end

    test "render link button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.render id="link-button" type="link" link_params={%{"navigate" => "/foo"}}>
          Link button
        </Button.render>
        """)

      item =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s|a[navigate="/foo"]|)

      assert Floki.text(item) =~ "Link button"
    end

    test "render icons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.render
          id="button"
          type="action"
          style="solid"
          left_icon="hero-arrow-long-left"
          right_icon="hero-arrow-long-right"
        >
          Action button
        </Button.render>
        <Button.render
          id="button"
          type="submit"
          style="outline"
          left_icon="hero-arrow-long-left"
          right_icon="hero-arrow-long-right"
        >
          Submit button
        </Button.render>
        <Button.render
          id="button"
          type="link"
          style="text"
          left_icon="hero-arrow-long-left"
          right_icon="hero-arrow-long-right"
        >
          Link button
        </Button.render>
        <Button.render
          id="button"
          type="link"
          style="ghost"
          left_icon="hero-arrow-long-left"
          right_icon="hero-arrow-long-right"
        >
          Link button
        </Button.render>
        """)

      left_icon =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s|.hero-arrow-long-left|)

      right_icon =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s|.hero-arrow-long-right|)

      assert Enum.count(left_icon) == 4
      assert Enum.count(right_icon) == 4
    end

    test "render disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.render
          id="button"
          type="action"
          style="solid"
          left_icon="hero-arrow-long-left"
          right_icon="hero-arrow-long-right"
          enabled={false}
        >
          Disabled button
        </Button.render>
        <Button.render
          id="button"
          type="action"
          style="outline"
          left_icon="hero-arrow-long-left"
          right_icon="hero-arrow-long-right"
          enabled={false}
        >
          Disabled button
        </Button.render>
        <Button.render
          id="button"
          type="action"
          style="text"
          left_icon="hero-arrow-long-left"
          right_icon="hero-arrow-long-right"
          enabled={false}
        >
          Disabled button
        </Button.render>
        <Button.render
          id="button"
          type="action"
          style="ghost"
          left_icon="hero-arrow-long-left"
          right_icon="hero-arrow-long-right"
          enabled={false}
        >
          Disabled button
        </Button.render>
        """)

      item =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s|button[disabled]|)

      assert Enum.count(item) == 4
    end

    test "render button style solid" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.render id="button" type="action" style="solid" color="blue">
          Text button
        </Button.render>
        """)

      item =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s|.text-white.bg-blue-500|)

      assert Enum.count(item) == 1
    end

    test "render button style outline" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.render id="button" type="action" style="outline" color="blue">
          Text button
        </Button.render>
        """)

      item =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s|.text-blue-600.border-blue-600|)

      assert Enum.count(item) == 1
    end

    test "render button style text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.render id="button" type="action" style="text" color="blue">
          Text button
        </Button.render>
        """)

      item =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s|.border-blue-600.bg-blue-500|)

      refute Enum.count(item) == 1
    end
  end
end
