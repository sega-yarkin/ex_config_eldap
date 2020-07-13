# ExConfigEldap

Types for `ExConfig` to support `:eldap` Erlang library.

## Installation

```elixir
def deps do
  [{:ex_config_eldap, git: "https://github.com/sega-yarkin/ex_config_eldap.git"}]
end
```

## `ExConfig.Type.EldapFilter`

Responsible for parsing LDAP filter string into type accepted by `:eldap.search/2`.

### Usage example

```elixir
# config/config.exs
use Mix.Config
alias ExConfig.Source.System
config :my_app,
  ldap_filter: {System, name: "LDAP_FILTER"}

# lib/my_app/config.ex
defmodule MyApp.Config do
  use ExConfig, otp_app: :my_app
  alias ExConfig.Type.EldapFilter

  env :ldap_filter, EldapFilter
end
```

Then in app:
```elixir
# LDAP_FILTER='(&(givenName=John)(sn=Doe))' iex -S mix
iex> MyApp.Config.ldap_filter
{:and,
 [
   equalityMatch: {:AttributeValueAssertion, 'givenName', 'John'},
   equalityMatch: {:AttributeValueAssertion, 'sn', 'Doe'}
 ]}
```
