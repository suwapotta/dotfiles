return {
  {
    "neovim/nvim-lspconfig",

    opts = {
      servers = {
        arduino_language_server = {
          cmd = {
            "arduino-language-server",
            "-cli-config",
            "/home/suwapotta/.arduino15/arduino-cli.yaml",
            "-fqbn",
            "arduino:avr:uno",
          },
        },
      },
    },
  },
}
