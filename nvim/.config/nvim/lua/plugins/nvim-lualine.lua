return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    table.insert(opts.sections.lualine_z, {
      function()
        return "󰣇"
      end,
    })
  end,
}
