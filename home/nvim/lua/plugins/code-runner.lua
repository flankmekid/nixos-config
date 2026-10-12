-- ── Compile & run the current file ───────────────────────────────────────────
-- <F5>        run in a split terminal at the bottom
-- <leader>rf  run in a floating window
-- Compiled binaries go to /tmp/code_runner so lab folders don't fill up with
-- a.out-style junk. Every toolchain used here comes from modules/nixos/dev.nix.
local bin = "/tmp/code_runner"

-- Link raylib only for files that actually include it (CPATH/LIBRARY_PATH for
-- it are set in modules/nixos/dev.nix).
local raylib = '$(grep -q "raylib.h" $fileName && echo -lraylib)'

-- Save first so you never run a stale version of the file.
local function run(mode)
  return function()
    vim.cmd("silent! update")
    vim.cmd(mode and ("RunFile " .. mode) or "RunCode")
  end
end

return {
  {
    "CRAG666/code_runner.nvim",
    cmd = { "RunCode", "RunFile", "RunProject", "RunClose" },
    keys = {
      { "<F5>", run(), desc = "Compile & run (split)" },
      { "<leader>rf", run("float"), desc = "Compile & run (float)" },
    },
    opts = {
      mode = "term",
      focus = true,
      startinsert = true,
      term = { position = "bot", size = 15 },
      float = { border = "rounded", height = 0.8, width = 0.8 },
      filetype = {
        c = {
          'mkdir -p ' .. bin .. ' && cd $dir &&',
          'gcc -std=c17 -Wall -Wextra -g $fileName -o ' .. bin .. '/$fileNameWithoutExt -lm ' .. raylib .. ' &&',
          bin .. "/$fileNameWithoutExt",
        },
        cpp = {
          'mkdir -p ' .. bin .. ' && cd $dir &&',
          'g++ -std=c++20 -Wall -Wextra -g $fileName -o ' .. bin .. '/$fileNameWithoutExt ' .. raylib .. ' &&',
          bin .. "/$fileNameWithoutExt",
        },
        rust = {
          'mkdir -p ' .. bin .. ' && cd $dir &&',
          'rustc $fileName -o ' .. bin .. '/$fileNameWithoutExt &&',
          bin .. "/$fileNameWithoutExt",
        },
        -- Java 11+ runs a single source file directly, no javac step needed.
        java = 'cd $dir && java $fileName',
        -- .NET 8 can't run a lone .cs file; this runs the project in the file's folder.
        cs = 'cd $dir && dotnet run',
        python = 'cd $dir && python3 -u $fileName',
        r = 'cd $dir && Rscript $fileName',
        javascript = 'cd $dir && node $fileName',
        -- Node 24 strips TypeScript types natively.
        typescript = 'cd $dir && node $fileName',
        lua = 'cd $dir && nvim -l $fileName',
        sh = 'cd $dir && bash $fileName',
        zsh = 'cd $dir && zsh $fileName',
        tex = 'cd $dir && tectonic $fileName && zathura --fork $fileNameWithoutExt.pdf',
      },
    },
  },
}
