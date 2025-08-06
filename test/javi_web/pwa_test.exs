defmodule JaviWeb.PWATest do
  use ExUnit.Case
  alias JaviWeb.PWA

  test "manifest returns correct structure" do
    manifest = PWA.manifest()

    assert manifest.name == "Javi"
    assert manifest.short_name == "Javi"
    assert manifest.display == "standalone"
    assert manifest.theme_color == "#8b5cf6"
    assert manifest.background_color == "#0f172a"
    assert manifest.start_url == "/"
    assert manifest.scope == "/"
    assert manifest.lang == "en"
    assert manifest.categories == ["entertainment", "productivity", "lifestyle"]
    assert is_list(manifest.icons)
    assert is_list(manifest.shortcuts)
    assert is_list(manifest.screenshots)
  end

  test "icon_sizes returns correct icon configurations" do
    icons = PWA.icon_sizes()

    assert length(icons) == 8

    # Check that all icons have required fields
    Enum.each(icons, fn icon ->
      assert Map.has_key?(icon, :src)
      assert Map.has_key?(icon, :sizes)
      assert Map.has_key?(icon, :type)
      assert Map.has_key?(icon, :purpose)
      assert String.ends_with?(icon.src, ".png")
    end)
  end

  test "shortcuts returns correct shortcut configurations" do
    shortcuts = PWA.shortcuts()

    assert length(shortcuts) == 3

    # Check that all shortcuts have required fields
    Enum.each(shortcuts, fn shortcut ->
      assert Map.has_key?(shortcut, :name)
      assert Map.has_key?(shortcut, :short_name)
      assert Map.has_key?(shortcut, :description)
      assert Map.has_key?(shortcut, :url)
      assert Map.has_key?(shortcut, :icons)
    end)
  end

  test "meta_tags returns correct meta tag configurations" do
    meta_tags = PWA.meta_tags()

    assert length(meta_tags) == 8

    # Check that all meta tags have required fields
    Enum.each(meta_tags, fn tag ->
      assert Map.has_key?(tag, :name)
      assert Map.has_key?(tag, :content)
    end)
  end

  test "link_tags returns correct link tag configurations" do
    link_tags = PWA.link_tags()

    assert length(link_tags) == 5

    # Check that all link tags have required fields
    Enum.each(link_tags, fn tag ->
      assert Map.has_key?(tag, :rel)
      assert Map.has_key?(tag, :href)
    end)
  end

  test "app_name returns correct name" do
    assert PWA.app_name() == "Javi"
  end

  test "app_short_name returns correct short name" do
    assert PWA.app_short_name() == "Javi"
  end

  test "theme_color returns correct color" do
    assert PWA.theme_color() == "#8b5cf6"
  end

  test "background_color returns correct color" do
    assert PWA.background_color() == "#0f172a"
  end

  test "manifest_url returns correct URL" do
    assert PWA.manifest_url() == "/manifest.json"
  end

  test "service_worker_url returns correct URL" do
    assert PWA.service_worker_url() == "/sw.js"
  end

  test "pwa_script_url returns correct URL" do
    assert PWA.pwa_script_url() == "/pwa.js"
  end
end
