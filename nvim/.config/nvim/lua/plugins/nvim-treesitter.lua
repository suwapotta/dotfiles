return {
  {
    "nvim-treesitter/nvim-treesitter",

    opts = function(_, opts)
      opts.ensure_installed = {
        "lua",
        "vim",
        "bash",
        "kitty",
        "json",
        "arduino",
        "c",
        "cpp",
        "css",
        "systemverilog",
        "latex",
        "bibtex",
        "python",
        "norg",
        "scss",
        "svelte",
        "typst",
        "vue",
      }

      if type(opts.highlight) == "table" and type(opts.highlight.disable) == "table" then
        opts.highlight.disable = vim.tbl_filter(function(lang)
          return lang ~= "latex"
        end, opts.highlight.disable)
      end
    end,
  },
}
