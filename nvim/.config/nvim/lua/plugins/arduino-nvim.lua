return {
  "yuukiflow/Arduino-Nvim",

  dependencies = {
    "nvim-telescope/telescope.nvim",
    "neovim/nvim-lspconfig",
  },

  ft = "arduino",

  config = function()
    -- Load Arduino plugin for .ino files
    require("Arduino-Nvim")

    keys = {
      -- Delete default keybindings
      vim.keymap.del("n", "<Leader>au"),
      vim.keymap.del("n", "<Leader>ac"),
      vim.keymap.del("n", "<Leader>as"),
      vim.keymap.del("n", "<Leader>ag"),
      vim.keymap.del("n", "<Leader>am"),
      vim.keymap.del("n", "<Leader>al"),
      vim.keymap.del("n", "<Leader>ab"),
      vim.keymap.del("n", "<Leader>ap"),
      vim.keymap.del("n", "<Leader>ar"),

      -- Replace with localleader
      vim.keymap.set("n", "<localleader>au", ":InoUpload<CR>", { silent = true }), -- Upload code
      vim.keymap.set("n", "<localleader>ac", ":InoCheck<CR>", { silent = true }), -- Compile/check code
      vim.keymap.set("n", "<localleader>as", ":InoStatus<CR>", { silent = true }), -- Show current board and port status
      vim.keymap.set("n", "<localleader>ag", ":InoGUI<CR>", { silent = true }), -- Open GUI for setting board and port
      vim.keymap.set("n", "<localleader>am", ":InoMonitor<CR>", { silent = true }), -- Open Serial monitor with default port and baud rate
      vim.keymap.set("n", "<localleader>al", ":InoLib<CR>", { silent = true }),
      vim.keymap.set("n", "<localleader>ab", ":InoSelectBoard<CR>", { silent = true }), -- open board selection gui
      vim.keymap.set("n", "<localleader>ap", ":InoSelectPort<CR>", { silent = true }), -- open board selection gui
      vim.keymap.set("n", "<localleader>ar", ":InoUploadReset<CR>", { silent = true }), -- Upload with manual reset for UNO R4 WiFi
    }
  end,
}
