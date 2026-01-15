return {
  "folke/flash.nvim",
  config = function(_, opts)
    require("flash").setup(opts)
    -- Override backdrop highlight so text doesn't get greyed out
    vim.api.nvim_set_hl(0, "FlashBackDrop", { link = "NONE" })

    -- Override match highlighting so 'f'-like search is like '/'-like search
    vim.api.nvim_set_hl(0, "FlashLabel", { link = "SEARCH" })
  end,
}
