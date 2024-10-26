defmodule CanneryWeb.PackLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Ammo.Pack
  """

  use CanneryWeb, :live_component
  alias Cannery.Ammo.{Pack, Type}
  alias Cannery.{Accounts.User, Ammo, Containers, Containers.Container}
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  @spec mount(Socket.t()) :: {:ok, Socket.t()}
  def mount(socket) do
    {:ok, socket |> assign(:class, :all)}
  end

  @impl true
  @spec update(
          %{:pack => Pack.t(), :current_user => User.t(), optional(any) => any},
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{pack: _pack} = assigns, socket) do
    socket |> assign(assigns) |> update()
  end

  @spec update(Socket.t()) :: {:ok, Socket.t()}
  def update(%{assigns: %{current_user: current_user}} = socket) do
    socket =
      socket
      |> assign(:types, Ammo.list_types(current_user))
      |> assign_new(:containers, fn -> Containers.list_containers(current_user) end)

    {:ok, socket |> assign_changeset(%{})}
  end

  @impl true
  def handle_event("validate", %{"pack" => pack_params}, socket) do
    matched_class =
      case pack_params["class"] do
        "rifle" -> :rifle
        "shotgun" -> :shotgun
        "pistol" -> :pistol
        _other -> :all
      end

    socket =
      socket
      |> assign_changeset(pack_params, :validate)
      |> assign(:class, matched_class)

    {:noreply, socket}
  end

  def handle_event(
        "save",
        %{"pack" => pack_params},
        %{assigns: %{action: action}} = socket
      ) do
    save_pack(socket, action, pack_params)
  end

  # HTML Helpers

  @spec container_options([Container.t()]) :: [{String.t(), Container.id()}]
  defp container_options(containers) do
    containers |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
  end

  @spec type_options([Type.t()], Type.class() | :all) ::
          [{String.t(), Type.id()}]
  defp type_options(types, :all) do
    types |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
  end

  defp type_options(types, selected_class) do
    types
    |> Enum.filter(fn %{class: class} -> class == selected_class end)
    |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
  end

  # Save Helpers

  defp assign_changeset(
         %{assigns: %{action: action, pack: pack, current_user: user}} = socket,
         pack_params,
         changeset_action \\ nil
       ) do
    default_action =
      case action do
        create when create in [:new, :clone] -> :insert
        :edit -> :update
      end

    changeset =
      case default_action do
        :insert ->
          type = maybe_get_type(pack_params, user)
          container = maybe_get_container(pack_params, user)
          pack |> Pack.create_changeset(type, container, user, pack_params)

        :update ->
          pack |> Pack.update_changeset(pack_params, user)
      end

    changeset =
      if changeset_action do
        case changeset |> Changeset.apply_action(changeset_action) do
          {:ok, _data} -> changeset
          {:error, changeset} -> changeset
        end
      else
        changeset
      end

    socket |> assign(:changeset, changeset)
  end

  defp maybe_get_container(%{"container_id" => container_id}, user)
       when is_binary(container_id) do
    container_id |> Containers.get_container!(user)
  end

  defp maybe_get_container(_params_not_found, _user), do: nil

  defp maybe_get_type(%{"type_id" => type_id}, user)
       when is_binary(type_id) do
    type_id |> Ammo.get_type!(user)
  end

  defp maybe_get_type(_params_not_found, _user), do: nil

  defp save_pack(
         %{assigns: %{pack: pack, current_user: current_user, return_to: return_to}} = socket,
         :edit,
         pack_params
       ) do
    socket =
      case Ammo.update_pack(pack, pack_params, current_user) do
        {:ok, _pack} ->
          prompt = dgettext("prompts", "Ammo updated successfully")
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_pack(
         %{assigns: %{changeset: changeset, current_user: current_user, return_to: return_to}} =
           socket,
         action,
         %{"multiplier" => multiplier_str} = pack_params
       )
       when action in [:new, :clone] do
    socket =
      with {multiplier, _remainder} <- multiplier_str |> Integer.parse(),
           {:ok, {count, _packs}} <- Ammo.create_packs(pack_params, multiplier, current_user) do
        prompt =
          dngettext(
            "prompts",
            "Ammo added successfully",
            "Ammo added successfully",
            count
          )

        socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)
      else
        {:error, %Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)

        :error ->
          error_msg = dgettext("errors", "Could not parse number of copies")

          {:error, changeset} =
            changeset
            |> Changeset.add_error(:multiplier, error_msg)
            |> Changeset.apply_action(:insert)

          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end
end
