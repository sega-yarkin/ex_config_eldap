defmodule ExConfig.Type.EldapFilter do
  @moduledoc """
  LDAP filter parser for Erlang `:eldap` library.
  """
  use ExConfig.Type
  alias ExConfig.Type.EldapFilter.Parser
  defstruct []

  @type eldap_filter() :: term()

  @impl true
  def handle(data, _opts), do: do_handle(data)

  @doc """
  Parses the human-readable representation of LDAP filter to the internal format
  used by `:eldap` Erlang library.

  ## Example

      iex> ExConfig.Type.EldapFilter.parse("(&(givenName=John)(sn=Doe))")
      {:ok,
       {:and,
        [
          equalityMatch: {:AttributeValueAssertion, 'givenName', 'John'},
          equalityMatch: {:AttributeValueAssertion, 'sn', 'Doe'}
        ]}}
  """
  @spec parse(String.t) :: {:ok, eldap_filter} | {:error, String.t}
  def parse(str) when byte_size(str) > 0, do: do_handle(str)

  @spec parse!(String.t) :: eldap_filter | no_return
  def parse!(str) when byte_size(str) > 0 do
    case parse(str) do
      {:ok, result}    -> result
      {:error, reason} -> raise(reason)
    end
  end

  @doc false
  @spec error(:bad_data, any) :: {:error, String.t}
  def error(:bad_data, data), do: {:error, "Bad LDAP filter: '#{data}'"}

  @spec do_handle(String.t) :: {:ok, eldap_filter} | {:error, String.t}
  defp do_handle(data) when byte_size(data) > 0 do
    case Parser.filter(data) do
      {:ok, [result], _, _, _, _} -> {:ok, result}
      _ -> error(:bad_data, data)
    end
  end
  defp do_handle(data), do: error(:bad_data, data)
end

defmodule ExConfig.Type.EldapFilter.Parser do
  @moduledoc """
  LDAP filter parser helpers.

  References: RFC 2254, RFC 2251, https://ldap.com
  """

  import NimbleParsec

  to_chl = &map(&1, {String, :to_charlist, []})
  single_chl_tag = &unwrap_and_tag(to_chl.(&1), &2)

  attr  = utf8_string([?A..?Z, ?a..?z, ?0..?9, ?-, ?;, ?.], min: 1)
  value = utf8_string([not: ?*, not: ?(, not: ?), not: 0], min: 1)

  b_par = string("(")
  e_par = string(")")

  #---------------------------------------------------------
  equal   = string("=")  |> replace(:equalityMatch)
  approx  = string("~=") |> replace(:approxMatch)
  greater = string(">=") |> replace(:greaterOrEqual)
  less    = string("<=") |> replace(:lessOrEqual)
  filtertype = choice([equal, approx, greater, less])

  simple =
    empty()
    |> concat(to_chl.(attr))
    |> concat(filtertype)
    |> concat(to_chl.(value))
    |> lookahead(e_par)
    |> reduce({:simple_item_eldap, []})

  defp simple_item_eldap([attr, type, value]),
    do: apply(:eldap, type, [attr, value])

  #---------------------------------------------------------
  present =
    empty()
    |> concat(to_chl.(attr))
    |> ignore(string("=*"))
    |> lookahead(e_par)
    |> reduce({:present_item_eldap, []})

  defp present_item_eldap([attr]), do: :eldap.present(attr)

  #---------------------------------------------------------
  sub_any = single_chl_tag.(value, :any) |> ignore(string("*"))
  substring =
    empty()
    |> concat(to_chl.(attr))
    |> ignore(string("="))
    |>   optional(single_chl_tag.(value, :initial))
    |>   ignore(string("*"))
    |>   repeat(sub_any)
    |>   optional(single_chl_tag.(value, :final))
    |> lookahead(e_par)
    |> reduce({:substring_item_eldap, []})

  defp substring_item_eldap([attr | subs]), do: :eldap.substrings(attr, subs)

  #---------------------------------------------------------
  ext_attr  = single_chl_tag.(attr, :type)
  ext_dn    = replace(string(":dn"), {:dnAttributes, true})
  ext_rule  = ignore(string(":")) |> concat(single_chl_tag.(attr, :matchingRule))
  ext_value = single_chl_tag.(value, :value)
  extensible =
    choice([
      # attr [":dn"] [":" matchingrule] ":=" value
      ext_attr
      |> optional(ext_dn)
      |> optional(ext_rule)
      |> ignore(string(":="))
      |> concat(ext_value)
      |> lookahead(e_par),
      #      [":dn"]  ":" matchingrule  ":=" value
      optional(ext_dn)
      |> concat(ext_rule)
      |> ignore(string(":="))
      |> concat(ext_value)
      |> lookahead(e_par),
    ])
    |> reduce({:extensibleitem_eldap, []})

  defp extensibleitem_eldap(attrs) do
    {value, attrs} = Keyword.pop(attrs, :value)
    :eldap.extensibleMatch(value, attrs)
  end

  #---------------------------------------------------------
  item = choice([simple, present, substring, extensible])

  container =
    choice([
      replace(string("&"), :and) |> repeat(parsec(:filter)),
      replace(string("|"), :or ) |> repeat(parsec(:filter)),
      replace(string("!"), :not) |> parsec(:filter),
    ])
    |> reduce({:container_eldap, []})

  defp container_eldap([:and | rest]), do: :eldap.and(rest)
  defp container_eldap([:or  | rest]), do: :eldap.or (rest)
  defp container_eldap([:not,  rest]), do: :eldap.not(rest)

  filtercomp = choice([container, item])

  defparsec :filter,
    empty()
    |> ignore(b_par)
    |> concat(filtercomp)
    |> ignore(e_par)

end
