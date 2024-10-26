defmodule Cannery do
  @moduledoc """
  Cannery keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def context do
    quote do
      use Gettext, backend: CanneryWeb.Gettext
      import Ecto.Query
      alias Cannery.Accounts.User
      alias Cannery.Repo
      alias Ecto.{Changeset, Multi, Queryable, UUID}
    end
  end

  def schema do
    quote do
      use Ecto.Schema
      use Gettext, backend: CanneryWeb.Gettext
      import Ecto.{Changeset, Query}
      alias Cannery.Accounts.User
      alias Ecto.{Association, Changeset, Queryable, UUID}

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end

  @doc """
  When used, dispatch to the appropriate context/schema/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
