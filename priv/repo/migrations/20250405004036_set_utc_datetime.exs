defmodule Cannery.Repo.Migrations.SetUtcDatetime do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :confirmed_at, :utc_datetime_usec, from: :naive_datetime
      modify :inserted_at, :utc_datetime_usec, from: :naive_datetime
      modify :updated_at, :utc_datetime_usec, from: :naive_datetime
    end

    alter table(:users_tokens) do
      modify :inserted_at, :utc_datetime_usec, from: :naive_datetime
    end

    alter table(:tags) do
      modify :inserted_at, :utc_datetime_usec, from: :naive_datetime
      modify :updated_at, :utc_datetime_usec, from: :naive_datetime
    end

    alter table(:types) do
      modify :inserted_at, :utc_datetime_usec, from: :naive_datetime
      modify :updated_at, :utc_datetime_usec, from: :naive_datetime
    end

    alter table(:containers) do
      modify :inserted_at, :utc_datetime_usec, from: :naive_datetime
      modify :updated_at, :utc_datetime_usec, from: :naive_datetime
    end

    alter table(:packs) do
      modify :inserted_at, :utc_datetime_usec, from: :naive_datetime
      modify :updated_at, :utc_datetime_usec, from: :naive_datetime
    end

    alter table(:invites) do
      modify :disabled_at, :utc_datetime_usec, from: :naive_datetime
      modify :inserted_at, :utc_datetime_usec, from: :naive_datetime
      modify :updated_at, :utc_datetime_usec, from: :naive_datetime
    end

    alter table(:container_tags) do
      modify :inserted_at, :utc_datetime_usec, from: :naive_datetime
      modify :updated_at, :utc_datetime_usec, from: :naive_datetime
    end

    alter table(:shot_records) do
      modify :inserted_at, :utc_datetime_usec, from: :naive_datetime
      modify :updated_at, :utc_datetime_usec, from: :naive_datetime
    end

  end
end
