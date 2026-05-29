--INFO: lsp log level
vim.lsp.log.set_level(vim.log.levels.OFF)

--INFO: diagnostic config
vim.diagnostic.config({
    underline = true,
    update_in_insert = false,
    virtual_text = {
	spacing = 4,
	source = "if_many",
	prefix = function(diagnostic)
	    local icons = {
		[vim.diagnostic.severity.ERROR] = "",
		[vim.diagnostic.severity.WARN]  = "",
		[vim.diagnostic.severity.INFO]  = "",
		[vim.diagnostic.severity.HINT]  = "",
	    }
	    return icons[diagnostic.severity] or "●"
	end
    },
    severity_sort = true,
    signs = {
	text = {
	    [vim.diagnostic.severity.ERROR] = " ",
	    [vim.diagnostic.severity.WARN] = " ",
	    [vim.diagnostic.severity.HINT] = " ",
	    [vim.diagnostic.severity.INFO] = " ",
	},
    }
})
--INFO: inlay_hint         
vim.lsp.inlay_hint.enable(true)

--INFO: codelens 
vim.lsp.codelens.enable(true)


--INFO: lsp client enable
local lsp_clients = { "ty" , "rust_analyzer" }
for _, lsp in ipairs(lsp_clients) do
    vim.lsp.enable(lsp)
end
