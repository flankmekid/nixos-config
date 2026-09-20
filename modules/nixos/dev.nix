# ── Development toolchains for ASE CSIE (Informatică Economică) ───────────────
{ config, pkgs, lib, ... }:
{
  # ── nix-ld: makes dynamically-linked binaries that were NOT built for NixOS
  #    actually run. This is close to essential for you: uni hands out
  #    prebuilt .jar launchers/compilers, VS Code extensions ship binary
  #    language servers, and CTF challenges are literally random ELF binaries.
  #    Without it you get "No such file or directory" on a file that exists.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      glib
      libxml2
      icu
      libgcc
      xz
      # X/GUI libs — enough for most prebuilt GUI tools and Electron blobs.
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libXtst
      xorg.libXi
      xorg.libxcb
      libxkbcommon
      fontconfig
      freetype
      nss
      nspr
      at-spi2-atk
      cups
      dbus
      expat
      alsa-lib
    ];
  };

  # ── Databases.
  # PostgreSQL runs as a service so it survives reboots and `psql` just works.
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    # Local-only. `trust` for unix-socket connections keeps coursework painless;
    # nothing listens on the network, so this is not exposed.
    enableTCPIP = false;
    authentication = lib.mkForce ''
      local all all trust
      host  all all 127.0.0.1/32 trust
      host  all all ::1/128      trust
    '';
    ensureDatabases = [ "dawid" ];
    ensureUsers = [{
      name = "dawid";
      ensureClauses = { superuser = true; createdb = true; createrole = true; };
    }];
  };

  # MySQL/MariaDB — off by default because two DB servers idling on a laptop is
  # wasteful. Flip to true the week a course actually needs it.
  services.mysql = {
    enable = false;
    package = pkgs.mariadb;
  };

  # ── Oracle Database.
  # ASE courses often require Oracle. There is no sane native NixOS package —
  # the only workable route is the official container image. Everything you
  # need (docker, sqlcl) is already installed below; to bring up Oracle XE:
  #
  #   docker run -d --name oracle-xe -p 1521:1521 \
  #     -e ORACLE_PASSWORD=oracle \
  #     gvenzl/oracle-free:slim
  #   sql system/oracle@localhost:1521/FREEPDB1     # sqlcl, installed below
  #
  # Uncomment to have it start automatically with the machine:
  # virtualisation.oci-containers.containers.oracle-xe = {
  #   image = "gvenzl/oracle-free:slim";
  #   ports = [ "1521:1521" ];
  #   environment.ORACLE_PASSWORD = "oracle";
  #   volumes = [ "oracle-data:/opt/oracle/oradata" ];
  # };

  environment.systemPackages = with pkgs; [
    # ── C / C++ (also the base for CTF binary exploitation)
    gcc
    clang
    clang-tools # clangd LSP, clang-format, clang-tidy
    gdb
    lldb
    valgrind
    cmake
    gnumake
    ninja
    pkg-config
    bear # generates compile_commands.json so clangd understands Makefile projects

    # ── Java (JDK 21 LTS)
    jdk21
    maven
    gradle
    jdt-language-server

    # ── C# / .NET
    # `dotnet-sdk` tracks the current default. To pin an LTS your course wants,
    # swap for dotnet-sdk_8 / dotnet-sdk_9 and rebuild.
    dotnet-sdk
    omnisharp-roslyn
    netcoredbg # debugger, used by nvim-dap and VSCodium

    # ── Python + data/stats
    (python3.withPackages (ps: with ps; [
      numpy
      pandas
      scipy
      matplotlib
      seaborn
      statsmodels
      scikit-learn
      jupyterlab
      ipython
      requests
      sqlalchemy
      psycopg2
      openpyxl # read/write .xlsx for coursework
      beautifulsoup4
      pwntools # CTF exploit scripting — belongs with Python, not the sec module
    ]))
    uv # fast venv/dependency manager for per-project envs
    ruff # linter + formatter
    basedpyright # type-checking LSP

    # ── R, for econometrics/statistics courses
    R

    # ── Databases: clients and GUI
    postgresql_17 # psql client
    dbeaver-bin # GUI client for Postgres/MySQL/Oracle/SQLite
    sqlite
    sqlcl # Oracle's CLI client, works against the container above
    pgformatter

    # ── LaTeX. scheme-medium is ~2GB and covers essentially all coursework.
    # Swap for texliveFull if a template pulls something exotic.
    texliveMedium
    texlab # LaTeX LSP
    zathura # PDF viewer with SyncTeX (jump editor <-> PDF)

    # ── Office + documents
    libreoffice-fresh
    hunspell
    hunspellDicts.en_US
    hunspellDicts.ro_RO
    pandoc

    # ── Shell / web / misc LSPs and formatters (used by Neovim and VSCodium)
    nixd
    nixfmt-rfc-style
    lua-language-server
    stylua
    bash-language-server
    shellcheck
    shfmt
    yaml-language-server
    taplo # TOML
    marksman # Markdown LSP
    vscode-langservers-extracted # json/html/css/eslint servers
    nodejs
    typescript

    # ── General tooling
    direnv
    nix-direnv
    just
    jq
    yq-go
    httpie
    lazygit
    delta # nicer git diffs
    gh
  ];

  # direnv: per-project dev shells that load automatically when you cd in.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };

  # Java apps (IntelliJ, uni-issued tools) need this set to find the JDK.
  environment.sessionVariables.JAVA_HOME = "${pkgs.jdk21}";

  # Stop .NET phoning home and looking for a global SDK install.
  environment.sessionVariables.DOTNET_CLI_TELEMETRY_OPTOUT = "1";
  environment.sessionVariables.DOTNET_ROOT = "${pkgs.dotnet-sdk}/share/dotnet";
}
