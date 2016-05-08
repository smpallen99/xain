defmodule Xain.Mixfile do
  use Mix.Project

  @version "0.5.3"

  def project do
    [app: :xain,
     version: @version,
     elixir: "~> 1.0",
     package: package,
     deps: [],
     description: """
     An html DSL package.
     """
   ]
  end

  def application do
    [applications: [:logger]]
  end

  defp package do
    [ maintainers: ["Stephen Pallen"],
      licenses: ["MIT"],
      links: %{ "Github" => "https://github.com/smpallen99/xain"},
      files: ~w(lib README.md mix.exs LICENSE)]
  end
end
