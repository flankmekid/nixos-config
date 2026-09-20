-- ── LSP servers, pointed at the Nix-provided binaries ────────────────────────
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- Inlay hints are genuinely useful in C#/Java/C++ coursework.
      inlay_hints = { enabled = true },
      diagnostics = {
        virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
        severity_sort = true,
      },
      servers = {
        -- Nix. The `options` exprs give you completion and inline docs for
        -- NixOS/home-manager options while editing this very repo.
        -- Adjust the path if you ever move the flake.
        nixd = {
          settings = {
            nixd = {
              formatting = { command = { "nixfmt" } },
              options = {
                nixos = {
                  expr = '(builtins.getFlake "/home/dawid/nixos-config").nixosConfigurations.laptop.options',
                },
                home_manager = {
                  expr = '(builtins.getFlake "/home/dawid/nixos-config").nixosConfigurations.laptop.options.home-manager.users.type.getSubOptions []',
                },
              },
            },
          },
        },

        -- C/C++. These flags stop clangd choking on GCC-specific headers.
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
        },

        -- Python: basedpyright for types, ruff for lint/format.
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
                autoImportCompletions = true,
              },
            },
          },
        },
        ruff = {},

        -- LaTeX. Build with tectonic (self-contained, avoids texlive path
        -- surprises); forward-search jumps Zathura to your cursor position.
        texlab = {
          settings = {
            texlab = {
              build = {
                executable = "tectonic",
                args = { "-X", "compile", "%f", "--synctex", "--keep-logs", "--keep-intermediates" },
                onSave = true,
              },
              forwardSearch = {
                executable = "zathura",
                args = { "--synctex-forward", "%l:1:%f", "%p" },
              },
            },
          },
        },

        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              codeLens = { enable = true },
              hint = { enable = true },
            },
          },
        },

        bashls = {},
        marksman = {},
        yamlls = {},
        taplo = {},
      },
    },
  },

  -- Formatters — again, all Nix-provided.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
        lua = { "stylua" },
        python = { "ruff_format", "ruff_organize_imports" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        java = { "google-java-format" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        sql = { "sqlfluff" },
        markdown = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
      },
    },
  },
}
