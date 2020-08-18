defmodule ExConfigEldap.Helpers do
  @moduledoc """
  A set of helpers for `:eldap` library.
  """

  @doc """
  A small helper to clarify which format is needed by `:eldap` to work correctly
  with UTF8 strings.
  """
  @spec string_to_list(String.t) :: [byte]
  def string_to_list(str) when is_binary(str), do: :binary.bin_to_list(str)
  @compile {:inline, string_to_list: 1}

  @doc """
  Helper for ExConfig to transform Elixir string value to valid `:eldap` string.
  """
  @spec from_string(ExConfig.Param.t | map) :: ExConfig.Param.t | map
  def from_string(%ExConfig.Param{data: data} = param) when is_binary(data) do
    %{param | data: string_to_list(data)}
  end
  def from_string(param = %{}), do: param
end
