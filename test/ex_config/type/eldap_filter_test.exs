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
end
