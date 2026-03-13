defmodule Cannery.Utils do
  @moduledoc """
  General-purpose utility functions used across the application.
  """

  @doc """
  Wraps a value in a tagged tuple for pipeline-friendly callback returns.

  ## Examples

      iex> socket |> assign(:key, "val") |> wrap(:ok)
      {:ok, %{key: "val"}}

      iex> socket |> assign(:flash, "saved") |> wrap(:noreply)
      {:noreply, %{flash: "saved"}}

  """
  @spec wrap(value, atom()) :: {atom(), value} when value: var
  def wrap(value, key), do: {key, value}

  @doc """
  Extracts the value from a tagged tuple, asserting the expected tag.

  Raises `MatchError` if the tag does not match.

  ## Examples

      iex> unwrap({:ok, 42}, :ok)
      42

      iex> unwrap({:error, "boom"}, :error)
      "boom"

  """
  @spec unwrap({atom(), value}, atom()) :: value when value: var
  def unwrap(value, key) do
    {^key, ret} = value
    ret
  end

  @doc """
  Conditionally pipes a value through a function.

  If `condition` is truthy, applies `if_func` to `value`.
  Otherwise applies `else_func` if provided, or returns `value` unchanged.

  ## Examples

      iex> pipe_if([], true, &["item" | &1])
      ["item"]

      iex> pipe_if([], false, &["item" | &1])
      []

      iex> pipe_if(1, false, &(&1 + 10), &(&1 + 20))
      21

  """
  @spec pipe_if(value, term(), (value -> result), (value -> result) | nil) :: value | result
        when value: var, result: var
  def pipe_if(value, condition, if_func, else_func \\ nil) do
    if condition do
      if_func.(value)
    else
      if else_func, do: else_func.(value), else: value
    end
  end

  @doc """
  Recursively retrieves a nested value from a map or struct using a list of keys.

  Returns `default` if any intermediate value is `nil`.

  ## Examples

      iex> dig(%{a: %{b: 1}}, [:a, :b])
      1

      iex> dig(%{a: nil}, [:a, :b], "fallback")
      "fallback"

  """
  @spec dig(map() | struct() | nil, [atom()], term()) :: term()
  def dig(struct_or_map, attrs, default \\ nil)
  def dig(nil, _attrs, default), do: default
  def dig(struct_or_map, [], _default), do: struct_or_map

  def dig(struct_or_map, [head | tail], default) do
    struct_or_map
    |> Map.get(head)
    |> dig(tail, default)
  end
end
