return {
  "lervag/vimtex",
  lazy = true,
  ft = { "tex", "bib", "latex" },

  init = function()
    vim.g.vimtex_view_method = "zathura_simple"
  end,
}
