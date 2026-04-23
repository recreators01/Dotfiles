vim.api.nvim_create_autocmd('FileType', {
    callback = function() 
	if vim.treesitter.language.add(vim.bo.filetype) then
	    vim.treesitter.start()
	end
    end,
})
