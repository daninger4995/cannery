defmodule Cannery.Repo.Migrations.MoveStagedToContainers do
  use Ecto.Migration

  def change do
    alter table(:packs) do
      remove :staged
    end

    alter table(:containers) do
      add :staged, :boolean, default: false
    end
  end
end
