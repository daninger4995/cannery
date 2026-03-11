defmodule CanneryWeb.ContainerLive.Show do
  @moduledoc """
  Liveview for showing and editing a Cannery.Containers.Container
  """

  use CanneryWeb, :live_view
  alias Cannery.{Accounts.User, ActivityLog, Ammo, Containers, Containers.Container}
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(_params, _session, socket),
    do: {:ok, socket |> assign(class: :all, view_table: true)}

  @impl true
  def handle_params(
        %{"id" => id} = params,
        _session,
        %{assigns: %{current_user: current_user}} = socket
      ) do
    socket =
      socket
      |> assign_class(params)
      |> assign(:view_table, true)
      |> render_container(id, current_user)

    {:noreply, socket}
  end

  defp assign_class(socket, %{"class" => class}) when class in ~w(rifle shotgun pistol),
    do: socket |> assign(:class, String.to_existing_atom(class))

  defp assign_class(socket, _params), do: socket |> assign(:class, :all)

  @impl true
  def handle_info(
        {CanneryWeb.ContainerLive.EditTagsComponent, {:tags_updated, {level, msg}}},
        socket
      ) do
    socket |> put_flash(level, msg) |> render_container() |> wrap(:noreply)
  end

  @impl true
  def handle_event(
        "delete_tag",
        %{"tag-id" => tag_id},
        %{assigns: %{container: container, current_user: current_user}} = socket
      ) do
    socket =
      case Containers.get_tag(tag_id, current_user) do
        {:ok, tag} ->
          _count = Containers.remove_tag!(container, tag, current_user)

          prompt =
            dgettext("prompts", "%{tag_name} has been removed from %{container_name}",
              tag_name: tag.name,
              container_name: container.name
            )

          socket |> put_flash(:info, prompt) |> render_container()

        {:error, :not_found} ->
          socket |> put_flash(:error, dgettext("errors", "Tag not found"))
      end

    {:noreply, socket}
  end

  def handle_event(
        "delete_container",
        _params,
        %{assigns: %{container: container, current_user: current_user}} = socket
      ) do
    socket =
      Containers.delete_container(container, current_user)
      |> case do
        {:ok, %{name: container_name}} ->
          prompt = dgettext("prompts", "%{name} has been deleted", name: container_name)
          socket |> put_flash(:info, prompt) |> push_navigate(to: ~p"/containers")

        {:error, %{action: :delete, errors: [packs: packs_error], valid?: false} = changeset} ->
          prompt =
            dgettext("errors", "Could not delete %{name}: %{error}",
              name: changeset |> Changeset.get_field(:name, "container"),
              error: translate_error(packs_error)
            )

          socket |> put_flash(:error, prompt)

        {:error, _changeset} ->
          socket |> put_flash(:error, dgettext("errors", "Could not delete container"))
      end

    {:noreply, socket}
  end

  def handle_event(
        "toggle_staged",
        _params,
        %{assigns: %{container: container, current_user: current_user}} = socket
      ) do
    {:ok, _container} =
      container
      |> Containers.update_container(current_user, %{"staged" => !container.staged})

    {:noreply, socket |> render_container()}
  end

  def handle_event("toggle_table", _params, %{assigns: %{view_table: view_table}} = socket) do
    {:noreply, socket |> assign(:view_table, !view_table) |> render_container()}
  end

  def handle_event(
        "change_class",
        %{"type" => %{"class" => class}},
        %{assigns: %{container: container}} = socket
      ) do
    {:noreply, socket |> push_patch(to: ~p"/container/#{container}?class=#{class}")}
  end

  @spec render_container(Socket.t(), Container.id(), User.t()) :: Socket.t()
  defp render_container(
         %{assigns: %{class: class, live_action: live_action}} = socket,
         id,
         current_user
       ) do
    %{id: container_id, name: container_name} =
      container = Containers.get_container!(id, current_user)

    packs = Ammo.list_packs(current_user, container_id: container_id, class: class)
    original_counts = packs |> Ammo.get_original_counts(current_user)
    cprs = packs |> Ammo.get_cprs(current_user)
    last_used_dates = packs |> ActivityLog.get_last_used_dates(current_user)

    page_title =
      case live_action do
        :show -> container_name
        :edit -> gettext("Edit %{name}", name: container_name)
        :edit_tags -> gettext("Edit %{name} tags", name: container_name)
      end

    socket
    |> assign(
      container: container,
      round_count: Ammo.get_round_count(current_user, container_id: container.id),
      packs_count: Ammo.get_packs_count(current_user, container_id: container.id),
      packs: packs,
      original_counts: original_counts,
      cprs: cprs,
      last_used_dates: last_used_dates,
      page_title: page_title
    )
  end

  @spec render_container(Socket.t()) :: Socket.t()
  defp render_container(
         %{assigns: %{container: %{id: container_id}, current_user: current_user}} = socket
       ) do
    socket |> render_container(container_id, current_user)
  end
end
