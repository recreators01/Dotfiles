return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer Local Keymaps (which-key)",
        },
        {
            "<C-/>",
            function()
                -- 如果终端窗口存在 → 只隐藏窗口
                if vim.g.toggle_term_win and vim.api.nvim_win_is_valid(vim.g.toggle_term_win) then
                    vim.api.nvim_set_current_win(vim.g.toggle_term_win)
                    vim.cmd("hide")
                    vim.g.toggle_term_win = nil
                    return
                end

                -- 如果终端 buffer 还在 → 重新打开
                if vim.g.toggle_term_buf and vim.api.nvim_buf_is_valid(vim.g.toggle_term_buf) then
                    vim.cmd("belowright split | resize 15")
                    vim.api.nvim_set_current_buf(vim.g.toggle_term_buf)
                    vim.cmd("startinsert")
                    vim.g.toggle_term_win = vim.api.nvim_get_current_win()
                    return
                end

                -- 否则创建新终端
                vim.cmd("belowright split | resize 15 | terminal")
                vim.cmd("startinsert")
                vim.g.toggle_term_win = vim.api.nvim_get_current_win()
                vim.g.toggle_term_buf = vim.api.nvim_get_current_buf()
            end,
            mode = { "n", "i", "t" },
            desc = "Toggle Terminal",
        },
        { "<leader>cr", function() vim.lsp.codelens.run() end, desc = "Run CodeLens" },
    },
}
