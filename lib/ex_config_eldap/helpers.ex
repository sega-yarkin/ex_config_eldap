defmodule ExConfigEldap.Helpers do

  @doc """
  A small helper to clarify which format is needed by `:eldap` to work correctly
  with UTF8 strings.
  """
  @spec string_to_list(String.t) :: list
  def string_to_list(str) when is_binary(str), do: :binary.bin_to_list(str)
  @compile {:inline, string_to_list: 1}

  @doc """
  Helper for ExConfig to transform Elixir string value to valid `:eldap` string.
  """
  @spec from_string(ExConfig.Param.t) :: ExConfig.Param.t
  def from_string(%{data: data} = param) when is_binary(data) do
    %{param | data: string_to_list(data)}
  end
  def from_string(param), do: param
end
