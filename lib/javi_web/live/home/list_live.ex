defmodule JaviWeb.Home.ListLive do
  use JaviWeb, :live_view

  alias Javi.Accounts
  import JaviWeb.Components.BottomNavigation
  import JaviWeb.Components.Header

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    # Ensure default lists exist for the user
    ensure_default_lists(user)

    all_lists = Accounts.get_user_lists(user)

    # Separate default lists from custom lists
    default_lists =
      Enum.filter(all_lists, fn list ->
        list.list_type in ["watched", "watching", "favorites"]
      end)

    custom_lists =
      Enum.filter(all_lists, fn list ->
        list.list_type == "custom"
      end)

    socket =
      socket
      |> assign(:default_lists, default_lists)
      |> assign(:custom_lists, custom_lists)
      |> assign(:current_page, :media)
      |> assign(:show_modal, false)
      |> assign(:show_edit_modal, false)
      |> assign(:editing_list, nil)
      |> assign(:list_form, %{name: "", description: ""})
      |> assign(:edit_form, %{name: "", description: ""})

    {:ok, socket}
  end

  defp ensure_default_lists(user) do
    existing_lists = Accounts.get_user_lists(user)
    existing_list_types = Enum.map(existing_lists, & &1.list_type)

    default_list_types = ["watched", "watching", "favorites"]
    missing_types = default_list_types -- existing_list_types

    Enum.each(missing_types, fn list_type ->
      list_attrs =
        case list_type do
          "watched" ->
            %{
              name: "Assistidos",
              description: "Filmes e séries que você já assistiu",
              list_type: "watched",
              is_public: false
            }

          "watching" ->
            %{
              name: "Assistindo",
              description: "Filmes e séries que você está assistindo",
              list_type: "watching",
              is_public: false
            }

          "favorites" ->
            %{
              name: "Favoritos",
              description: "Seus filmes e séries favoritos",
              list_type: "favorites",
              is_public: false
            }
        end

      Accounts.create_list(user, list_attrs)
    end)
  end

  @impl true
  def handle_event("show_create_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: true)}
  end

  @impl true
  def handle_event("show_edit_modal", %{"id" => list_id}, socket) do
    user = socket.assigns.current_user
    list = Accounts.get_user_list(user, list_id)

    case list do
      nil ->
        {:noreply, socket}

      list ->
        edit_form = %{
          name: list.name,
          description: list.description || ""
        }

        {:noreply,
         socket
         |> assign(:show_edit_modal, true)
         |> assign(:editing_list, list)
         |> assign(:edit_form, edit_form)}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, false)
     |> assign(:list_form, %{name: "", description: ""})}
  end

  @impl true
  def handle_event("close_edit_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_edit_modal, false)
     |> assign(:editing_list, nil)
     |> assign(:edit_form, %{name: "", description: ""})}
  end

  @impl true
  def handle_event("validate_list", %{"name" => name, "description" => description}, socket) do
    {:noreply, assign(socket, list_form: %{name: name, description: description})}
  end

  @impl true
  def handle_event("validate_edit_list", %{"name" => name, "description" => description}, socket) do
    {:noreply, assign(socket, edit_form: %{name: name, description: description})}
  end

  @impl true
  def handle_event("validate_list", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_edit_list", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_list", %{"name" => name, "description" => description}, socket) do
    user = socket.assigns.current_user

    case Accounts.create_list(
           user,
           %{
             name: name,
             description: description,
             is_public: false,
             list_type: "custom"
           }
         ) do
      {:ok, _list} ->
        all_lists = Accounts.get_user_lists(user)

        # Separate default lists from custom lists
        default_lists =
          Enum.filter(all_lists, fn list ->
            list.list_type in ["watched", "watching", "favorites"]
          end)

        custom_lists =
          Enum.filter(all_lists, fn list ->
            list.list_type == "custom"
          end)

        {:noreply,
         socket
         |> assign(:default_lists, default_lists)
         |> assign(:custom_lists, custom_lists)
         |> assign(:show_modal, false)
         |> assign(:list_form, %{name: "", description: ""})}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_list", %{"name" => name, "description" => description}, socket) do
    user = socket.assigns.current_user
    editing_list = socket.assigns.editing_list

    case editing_list do
      nil ->
        {:noreply, socket}

      list ->
        case Accounts.update_list(list, %{name: name, description: description}) do
          {:ok, _updated_list} ->
            all_lists = Accounts.get_user_lists(user)

            # Separate default lists from custom lists
            default_lists =
              Enum.filter(all_lists, fn list ->
                list.list_type in ["watched", "watching", "favorites"]
              end)

            custom_lists =
              Enum.filter(all_lists, fn list ->
                list.list_type == "custom"
              end)

            {:noreply,
             socket
             |> assign(:default_lists, default_lists)
             |> assign(:custom_lists, custom_lists)
             |> assign(:show_edit_modal, false)
             |> assign(:editing_list, nil)
             |> assign(:edit_form, %{name: "", description: ""})}

          {:error, _changeset} ->
            {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_event("create_list", _params, socket) do
    # Handle case where parameters might be missing or malformed
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_list", %{"id" => list_id}, socket) do
    user = socket.assigns.current_user
    list = Accounts.get_user_list(user, list_id)

    case list do
      nil ->
        {:noreply, socket}

      list ->
        case Accounts.delete_list(list) do
          {:ok, _} ->
            all_lists = Accounts.get_user_lists(user)

            # Separate default lists from custom lists
            default_lists =
              Enum.filter(all_lists, fn list ->
                list.list_type in ["watched", "watching", "favorites"]
              end)

            custom_lists =
              Enum.filter(all_lists, fn list ->
                list.list_type == "custom"
              end)

            {:noreply,
             socket
             |> assign(:default_lists, default_lists)
             |> assign(:custom_lists, custom_lists)}

          {:error, _} ->
            {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_event("navigate_to_list", %{"list-id" => list_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/listas/#{list_id}")}
  end
end
