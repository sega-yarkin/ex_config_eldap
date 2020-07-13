defmodule ExConfig.Type.EldapFilter.ParserTest do
  use ExUnit.Case
  alias ExConfig.Type.EldapFilter.Parser

  defp filter(value) do
    with {:ok, [result], "", _, _, _} <- Parser.filter(value),
      do: {:ok, result},
      else: (_ -> :error)
  end

  defp eq(type, value), do: :eldap.equalityMatch(type, value)

  test "bad input" do
    assert filter("") == :error
    assert filter("()") == :error
    assert filter("(cn=*)a") == :error
    assert filter("(cn*cn=*)") == :error
  end

  test "presence" do
    assert filter("(cn=*)") == {:ok, :eldap.present('cn')}
    assert filter("(objectClass=*)") == {:ok, :eldap.present('objectClass')}
  end

  test "equality" do
    assert filter("(givenName=John)") == {:ok, eq('givenName', 'John')}
    assert filter("(cn=Babs Jensen)") == {:ok, eq('cn', 'Babs Jensen')}
    assert filter("(o=Parens R Us \\28for all your parenthetical needs\\29)") == {:ok, eq('o', 'Parens R Us \\28for all your parenthetical needs\\29')}
    assert filter("(1.3.6.1.4.1.1466.0=\\04\\02\\48\\69)") == {:ok, eq('1.3.6.1.4.1.1466.0', '\\04\\02\\48\\69')}
  end

  test "approximate" do
    assert filter("(givenName~=John)") == {:ok, :eldap.approxMatch('givenName', 'John')}
    assert filter("(cn~=Babs Jensen)") == {:ok, :eldap.approxMatch('cn', 'Babs Jensen')}
  end

  test "greater-or-equal" do
    assert filter("(targetAttribute>=10)") == {:ok, :eldap.greaterOrEqual('targetAttribute', '10')}
  end

  test "less-or-equal" do
    assert filter("(targetAttribute<=100)") == {:ok, :eldap.lessOrEqual('targetAttribute', '100')}
  end

  test "substring" do
    substrings = fn (attr, initial, any, final) ->
      subs = []
      subs = if final != nil, do: [{:final, final} | subs], else: subs
      subs = (for name <- any, do: {:any, name}) ++ subs
      subs = if initial != nil, do: [{:initial, initial} | subs], else: subs
      :eldap.substrings(attr, subs)
    end

    assert filter("(cn=John*)") == {:ok, substrings.('cn', 'John', [], nil)}
    assert filter("(cn=*John*)") == {:ok, substrings.('cn', nil, ['John'], nil)}
    assert filter("(cn=*John*Doe*)") == {:ok, substrings.('cn', nil, ['John', 'Doe'], nil)}
    assert filter("(cn=*Doe)") == {:ok, substrings.('cn', nil, [], 'Doe')}
    assert filter("(cn=J*o*h*n*D*o*e)") == {:ok, substrings.('cn', 'J', ['o', 'h', 'n', 'D', 'o'], 'e')}
    assert filter("(o=univ*of*mich*)") == {:ok, substrings.('o', 'univ', ['of', 'mich'], nil)}
    assert filter("(cn=*\\2A*)") == {:ok, substrings.('cn', nil, ['\\2A'], nil)}
  end

  test "extensible" do
    ematch = fn (value, type, dn?, mr) ->
      attrs = []
      attrs = if mr != nil, do: [{:matchingRule, mr} | attrs], else: attrs
      attrs = if dn?, do: [{:dnAttributes, true} | attrs], else: attrs
      attrs = if type != nil, do: [{:type, type} | attrs], else: attrs
      :eldap.extensibleMatch(value, attrs)
    end

    assert filter("(givenName:=John)") == {:ok, ematch.('John', 'givenName', nil, nil)}
    assert filter("(givenName:dn:=John)") == {:ok, ematch.('John', 'givenName', true, nil)}
    assert filter("(givenName:caseExactMatch:=John)") == {:ok, ematch.('John', 'givenName', nil, 'caseExactMatch')}
    assert filter("(givenName:dn:2.5.13.5:=John)") == {:ok, ematch.('John', 'givenName', true, '2.5.13.5')}
    assert filter("(:caseExactMatch:=John)") == {:ok, ematch.('John', nil, nil, 'caseExactMatch')}
    assert filter("(:dn:2.5.13.5:=John)") == {:ok, ematch.('John', nil, true, '2.5.13.5')}
  end

  test "AND" do
    assert filter("(&)") == {:ok, :eldap.and([])}
    assert filter("(&(givenName=John)(sn=Doe))") == {:ok, :eldap.and([
      eq('givenName', 'John'),
      eq('sn', 'Doe'),
    ])}
    assert filter("(&(attr1=a)(&(attr2=b)(&(attr3=c)(attr4=d))))") == {:ok, :eldap.and([
      eq('attr1', 'a'),
      :eldap.and([
        eq('attr2', 'b'),
        :eldap.and([
          eq('attr3', 'c'),
          eq('attr4', 'd'),
        ])
      ])
    ])}
  end

  test "OR" do
    assert filter("(|)") == {:ok, :eldap.or([])}
    assert filter("(|(givenName=John)(givenName=Jon)(givenName=Johnathan)(givenName=Jonathan))") == {:ok, :eldap.or([
      eq('givenName', 'John'),  eq('givenName', 'Jon'), eq('givenName', 'Johnathan'), eq('givenName', 'Jonathan'),
    ])}
  end

  test "NOT" do
    assert filter("(!(givenName=John))") == {:ok, :eldap.not(eq('givenName', 'John'))}
    assert filter("(!(cn=Tim Howes))") == {:ok, :eldap.not(eq('cn', 'Tim Howes'))}
  end

  test "complex" do
    assert filter("(&(objectClass=Person)(|(sn=Jensen)(cn=Babs J*)))") == {:ok,
      :eldap.and([
        eq('objectClass', 'Person'),
        :eldap.or([
          eq('sn', 'Jensen'),
          :eldap.substrings('cn', initial: 'Babs J'),
        ]),
      ])}
  end

end
