return {
  "catppuccin/nvim",
  opts = {
    transparent_background = true,

    float = {
      transparent = true,
      solid = true,
    },

    -- Force completion menu background to be transparent
    custom_highlights = function(colors)
      return {
        Pmenu = { bg = "none" },
        PmenuSel = { bg = colors.surface0, fg = "none" },
      }
    end,
  },
}
