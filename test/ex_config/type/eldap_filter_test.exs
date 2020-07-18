defmodule ExConfig.Type.EldapFilterTest do
  use ExUnit.Case
  alias ExConfig.Type.EldapFilter

  test "init/1" do
    assert %EldapFilter{} == ExConfig.Param.create_type_instance(EldapFilter, [])
  end

  test "handle" do
    handle   = &EldapFilter.handle(&1, %{})
    bad_data = &EldapFilter.error(:bad_data, &1)

    assert handle.("") == bad_data.("")
    assert handle.("()") == bad_data.("()")
    assert handle.("(givenName=John)") == {:ok, :eldap.equalityMatch('givenName', 'John')}
  end

  test "parse" do
    assert EldapFilter.parse("(givenName=John)") == {:ok, :eldap.equalityMatch('givenName', 'John')}
    assert EldapFilter.parse("()") == EldapFilter.error(:bad_data, "()")
    assert catch_error(EldapFilter.parse("")) == :function_clause

    rt_err = fn data ->
      {:error, msg} = EldapFilter.error(:bad_data, data)
      %RuntimeError{message: msg}
    end
    assert EldapFilter.parse!("(givenName=John)") == :eldap.equalityMatch('givenName', 'John')
    assert catch_error(EldapFilter.parse!("()")) == rt_err.("()")
    assert catch_error(EldapFilter.parse!("")) == :function_clause
  end
end
