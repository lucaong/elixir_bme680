defmodule ElixirBme680.MixProject do
  use Mix.Project

  @source_url "https://github.com/lucaong/elixir_bme680"

  def project do
    [
      app: :elixir_bme680,
      version: "0.2.2",
      elixir: "~> 1.7",
      compilers: [:elixir_make] ++ Mix.compilers,
      make_targets: ["all"],
      make_clean: ["clean"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: @source_url,
      docs: [
        main: "Bme680",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package() do
    [
      description: "An Elixir library to interface with the BME680 gas sensor",
      files: ["lib", "LICENSE", "mix.exs", "README.md", "src/*.c", "src/*.h", "src/linux/i2c-dev.h", "src_bme280/*.c", "src_bme280/*.h", "src_bme280/linux/i2c-dev.h", "Makefile"],
      maintainers: ["Luca Ongaro"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.6", runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
