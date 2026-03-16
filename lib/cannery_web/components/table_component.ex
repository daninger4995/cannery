defmodule CanneryWeb.Components.TableComponent do
  @moduledoc """
  Function component that presents a sortable table.

  Sort state is managed by the parent LiveComponent, which should call the
  helpers in this module and handle the "sort_by" event.
  """

  use CanneryWeb, :html
  alias Cannery.{ComparableDate, ComparableDateTime}
  require Integer

  attr :columns, :list, required: true
  attr :rows, :list, required: true
  attr :last_sort_key, :atom, required: true
  attr :sort_mode, :atom, required: true
  attr :target, :any, default: nil
  attr :row_class, :string, default: "bg-white"
  attr :alternate_row_class, :string, default: "bg-zinc-200"

  def table(assigns) do
    ~H"""
    <div class="w-full overflow-x-auto border border-zinc-600 rounded-lg shadow-lg bg-white">
      <table class="min-w-full table-auto text-center bg-white">
        <thead class="border-b border-primary-600">
          <tr>
            <th class="p-2 w-12">{gettext("Row")}</th>
            <%= for %{key: key, label: label} = column <- @columns do %>
              <%= if column |> Map.get(:sortable, true) do %>
                <th class={["p-2", column[:class]]}>
                  <span
                    class="cursor-pointer flex justify-center items-center space-x-2"
                    phx-click="sort_by"
                    phx-value-sort-key={key}
                    phx-target={@target}
                  >
                    <.icon name="chevron-up" class="shrink-0 size-4 opacity-0" />
                    <span class={if @last_sort_key == key, do: "underline"}>{label}</span>
                    <%= if @last_sort_key == key do %>
                      <%= case @sort_mode do %>
                        <% :asc -> %>
                          <.icon name="chevron-down" class="shrink-0 size-4" />
                        <% :desc -> %>
                          <.icon name="chevron-up" class="shrink-0 size-4" />
                      <% end %>
                    <% else %>
                      <.icon name="chevron-up" class="shrink-0 size-4 opacity-0" />
                    <% end %>
                  </span>
                </th>
              <% else %>
                <th class={["p-2 cursor-not-allowed", column[:class]]}>
                  {label}
                </th>
              <% end %>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={{values, i} <- @rows |> Enum.with_index()}
            :key={values[:row_id]}
            id={values[:row_id]}
            class={if i |> Integer.is_even(), do: @row_class, else: @alternate_row_class}
          >
            <td class="p-2">{i + 1}</td>
            <td :for={%{key: key} = value <- @columns} :key={key} class={["p-2", value[:class]]}>
              <%= case values |> Map.get(key) do %>
                <% {_custom_sort_value, value} -> %>
                  {value}
                <% value -> %>
                  {value}
              <% end %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Initializes sort state for a parent component's socket.

  Returns `{sort_key, sort_mode}`, preserving any existing sort state on the
  socket (so re-sorting after data changes keeps the user's chosen order).
  """
  def init_sort(socket, columns, assigns) do
    sort_key =
      if socket.assigns[:last_sort_key] do
        socket.assigns.last_sort_key
      else
        if assigns |> Map.has_key?(:initial_key) do
          assigns.initial_key
        else
          columns |> List.first(%{}) |> Map.get(:key)
        end
      end

    sort_mode = socket.assigns[:sort_mode] || Map.get(assigns, :initial_sort_mode, :asc)

    {sort_key, sort_mode}
  end

  @doc """
  Sorts rows by the given key, mode, and optional type.
  """
  def sort_rows(rows, key, sort_mode, type)
      when type in [ComparableDate, ComparableDateTime, Date, DateTime] do
    rows
    |> Enum.sort_by(
      fn row ->
        case row |> Map.get(key) do
          {custom_sort_key, _value} -> custom_sort_key
          value -> value
        end
      end,
      {sort_mode, type}
    )
  end

  def sort_rows(rows, key, sort_mode, _type) do
    rows
    |> Enum.sort_by(
      fn row ->
        case row |> Map.get(key) do
          {custom_sort_key, _value} -> custom_sort_key
          value -> value
        end
      end,
      sort_mode
    )
  end

  @doc """
  Returns the type for a given sort key from columns.
  """
  def get_sort_type(columns, sort_key) do
    columns |> Enum.find(%{}, fn %{key: key} -> key == sort_key end) |> Map.get(:type)
  end

  @doc """
  Handles a "sort_by" event by updating sort state on the socket.

  Call this from the parent component's `handle_event/3`, then rebuild rows
  from the original data so Rendered structs are freshly generated.
  """
  def apply_sort(socket, %{"sort-key" => key}) do
    key = key |> String.to_existing_atom()
    %{last_sort_key: last_sort_key, sort_mode: sort_mode} = socket.assigns

    sort_mode =
      case {key, sort_mode} do
        {^last_sort_key, :asc} -> :desc
        {^last_sort_key, :desc} -> :asc
        {_new_sort_key, _last_sort_mode} -> :asc
      end

    socket |> Phoenix.Component.assign(last_sort_key: key, sort_mode: sort_mode)
  end

  @doc """
  Conditionally composes elements into the columns list, supports maps and
  lists. Works tail to front in order for efficiency

      iex> []
      ...> |> maybe_compose_columns(%{label: "Column 3"}, true)
      ...> |> maybe_compose_columns(%{label: "Column 2"}, false)
      ...> |> maybe_compose_columns(%{label: "Column 1"})
      [%{label: "Column 1"}, %{label: "Column 3"}]

  """
  @spec maybe_compose_columns(list(), element_to_add :: list() | map()) :: list()
  @spec maybe_compose_columns(list(), element_to_add :: list() | map(), boolean()) :: list()
  def maybe_compose_columns(columns, element_or_elements, add? \\ true)

  def maybe_compose_columns(columns, elements, true) when is_list(elements),
    do: Enum.concat(elements, columns)

  def maybe_compose_columns(columns, element, true) when is_map(element), do: [element | columns]
  def maybe_compose_columns(columns, _element_or_elements, false), do: columns
end
