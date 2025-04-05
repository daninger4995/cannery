defmodule Cannery.Containers.ContainerTag do
  @moduledoc """
  Thru-table struct for associating Cannery.Containers.Container and
  Cannery.Containers.Tag.
  """

  use Cannery, :schema
  alias Cannery.Containers.{Container, Tag}

  schema "container_tags" do
    belongs_to :container, Container
    belongs_to :tag, Tag

    timestamps(type: :utc_datetime)
  end

  @type t :: %__MODULE__{
          id: id(),
          container: Container.t(),
          container_id: Container.id(),
          tag: Tag.t(),
          tag_id: Tag.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_container_tag :: %__MODULE__{}
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t() | new_container_tag())

  @doc false
  @spec create_changeset(new_container_tag(), Tag.t(), Container.t()) :: changeset()
  def create_changeset(
        container_tag,
        %Tag{id: tag_id, user_id: user_id},
        %Container{id: container_id, user_id: user_id}
      ) do
    container_tag
    |> change(tag_id: tag_id)
    |> change(container_id: container_id)
    |> validate_required([:tag_id, :container_id])
  end
end
