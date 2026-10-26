defmodule NervesSystemFairphone2.MixProject do
  use Mix.Project

  @github_organization "Spin42"
  @app :nerves_system_fairphone2
  @source_url "https://github.com/#{@github_organization}/#{@app}"
  @version Path.join(__DIR__, "VERSION")
           |> File.read!()
           |> String.trim()

  def project do
    [
      app: @app,
      version: @version,
      # Because we're using OTP 27, we need to enforce Elixir 1.17 or later.
      elixir: "~> 1.17",
      compilers: Mix.compilers() ++ [:nerves_package],
      nerves_package: nerves_package(),
      description: description(),
      package: package(),
      deps: deps(),
      aliases: [loadconfig: [&bootstrap/1]],
      docs: docs(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.build": :docs,
        "hex.publish": :docs
      }
    ]
  end

  def application do
    []
  end

  defp bootstrap(args) do
    set_target()
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  defp nerves_package do
    [
      type: :system,
      artifact_sites: [
        {:github_releases, "#{@github_organization}/#{@app}"}
      ],
      build_runner_opts: build_runner_opts(),
      platform: Nerves.System.BR,
      platform_config: [
        defconfig: "nerves_defconfig"
      ],
      # The :env key forwards env vars into Buildroot's crosscompile
      # environment. It's marketed as an LLVM-tooling helper, but in
      # practice every host package's `make` invocation inherits these too.
      # `TARGET_ARCH` collides with GNU make's implicit `COMPILE.c` recipe
      # (`$(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c`), which since
      # lz4 1.10.0's lib/Makefile started using `$(COMPILE.c)` produces
      # literally `gcc … arm -c …` and breaks the host-lz4 build. Since
      # this system uses GCC (not LLVM) for cross-compilation, none of
      # these need to be forwarded — Buildroot gets its target info from
      # TARGET_CONFIGURE_OPTS independently.
      checksum: package_files()
    ]
  end

  defp deps do
    [
      {:nerves, "~> 1.11", runtime: false},
      {:nerves_system_br, "1.35.3", runtime: false},
      {:nerves_toolchain_armv7_nerves_linux_gnueabihf, "~> 15.3.1", runtime: false},
      {:nerves_system_linter, "~> 0.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false}
    ]
  end

  defp description do
    """
    Nerves System - Fairphone 2
    """
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp package do
    [
      files: package_files(),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp package_files do
    [
      "rootfs_overlay",
      "extlinux",
      "scripts",
      "packages",
      "patches",
      "fwup_include",
      "fwup-ops.conf",
      "fwup.conf",
      "linux-6.15.defconfig",
      "busybox-fp2.fragment",
      "Config.in",
      "external.mk",
      "mix.exs",
      "nerves_defconfig",
      "post-build.sh",
      "post-createfs.sh",
      "README.md",
      "VERSION"
    ]
  end

  defp build_runner_opts() do
    # Download source files first to get download errors right away.
    [make_args: primary_site() ++ ["source", "all", "legal-info"]]
  end

  defp primary_site() do
    case System.get_env("BR2_PRIMARY_SITE") do
      nil -> []
      primary_site -> ["BR2_PRIMARY_SITE=#{primary_site}"]
    end
  end

  defp set_target() do
    if function_exported?(Mix, :target, 1) do
      apply(Mix, :target, [:target])
    else
      System.put_env("MIX_TARGET", "target")
    end
  end
end
