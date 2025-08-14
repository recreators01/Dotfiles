return {"nvim-treesitter/nvim-treesitter", branch = 'master', event = "VeryLazy",lazy = vim.fn.argc(-1) == 0, build = ":TSUpdate"}
