defmodule CanneryWeb.ContainerLive.EditTagsComponent do
  @moduledoc """
  Livecomponent that can add or remove a tag to a Container
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Containers}
  alias Cannery.Containers.{Container, Tag}
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{
            :container => Container.t(),
            :current_user => User.t(),
            optional(any) => any
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(
        %{container: _container, current_user: current_user} = assigns,
        socket
      ) do
    tags = Containers.list_tags(current_user)
    socket |> assign(assigns) |> assign(:tags, tags) |> wrap(:ok)
  end

  @impl true
  def handle_event(
        "save",
        %{"tag" => %{"tag_id" => tag_id}},
        %{
          assigns: %{
            tags: tags,
            container: container,
            current_user: current_user
          }
        } = socket
      ) do
    case tags |> Enum.find(fn %{id: id} -> tag_id == id end) do
      nil ->
        prompt = dgettext("errors", "Tag could not be added")
        send(self(), {__MODULE__, {:tags_updated, {:error, prompt}}})
        socket |> wrap(:noreply)

      %{name: tag_name} = tag ->
        _container_tag = Containers.add_tag!(container, tag, current_user)
        prompt = dgettext("prompts", "%{name} added successfully", name: tag_name)
        container = Containers.get_container!(container.id, current_user)
        send(self(), {__MODULE__, {:tags_updated, {:info, prompt}}})
        socket |> assign(:container, container) |> wrap(:noreply)
    end
  end

  def handle_event(
        "delete",
        %{"tag-id" => tag_id},
        %{
          assigns: %{
            tags: tags,
            container: container,
            current_user: current_user
          }
        } = socket
      ) do
    case tags |> Enum.find(fn %{id: id} -> tag_id == id end) do
      nil ->
        prompt = dgettext("errors", "Tag could not be removed")
        send(self(), {__MODULE__, {:tags_updated, {:error, prompt}}})
        socket |> wrap(:noreply)

      %{name: tag_name} = tag ->
        _container_tag = Containers.remove_tag!(container, tag, current_user)
        prompt = dgettext("prompts", "%{name} removed successfully", name: tag_name)
        container = Containers.get_container!(container.id, current_user)
        send(self(), {__MODULE__, {:tags_updated, {:info, prompt}}})
        socket |> assign(:container, container) |> wrap(:noreply)
    end
  end

  @spec tag_options([Tag.t()], Container.t()) :: [{String.t(), Tag.id()}]
  defp tag_options(tags, %Container{tags: container_tags}) do
    container_tags_map = container_tags |> Enum.map(fn %{id: id} -> id end) |> MapSet.new()

    tags
    |> Enum.reject(fn %{id: id} -> container_tags_map |> MapSet.member?(id) end)
    |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
  end
end
