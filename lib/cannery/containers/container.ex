defmodule Cannery.Containers.Container do
  @moduledoc """
  A container that holds ammunition and belongs to a user.
  """

  use Cannery, :schema
  alias Cannery.{Containers.ContainerTag, Containers.Tag}

  @derive {Jason.Encoder,
           only: [
             :desc,
             :id,
             :location,
             :name,
             :staged,
             :tags,
             :type
           ]}
  schema "containers" do
    field :desc, :string
    field :location, :string
    field :name, :string
    field :staged, :boolean, default: false
    field :type, :string

    field :user_id, :binary_id

    many_to_many :tags, Tag, join_through: ContainerTag

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{
          desc: String.t(),
          id: id(),
          location: String.t(),
          name: String.t(),
          staged: boolean(),
          type: String.t(),
          user_id: User.id(),
          tags: [Tag.t()] | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }
  @type new_container :: %__MODULE__{}
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t() | new_container())

  @doc false
  @spec create_changeset(new_container(), User.t(), attrs :: map()) :: changeset()
  def create_changeset(container, %User{id: user_id}, attrs) do
    container
    |> change(user_id: user_id)
    |> cast(attrs, [
      :desc,
      :location,
      :name,
      :staged,
      :type
    ])
    |> validate_length(:name, max: 255)
    |> validate_length(:type, max: 255)
    |> validate_required([
      :name,
      :staged,
      :type,
      :user_id
    ])
  end

  @doc false
  @spec update_changeset(t() | new_container(), attrs :: map()) :: changeset()
  def update_changeset(container, attrs) do
    container
    |> cast(attrs, [
      :desc,
      :location,
      :name,
      :staged,
      :type
    ])
    |> validate_length(:name, max: 255)
    |> validate_length(:type, max: 255)
    |> validate_required([
      :name,
      :staged,
      :type
    ])
  end
end
