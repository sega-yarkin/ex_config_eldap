%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/"]
      },
      checks: [
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Warning.LazyLogging, false},
      ],
    }
  ]
}