return {
	"neovim/nvim-lspconfig",
	opts = function()
		---@class PluginLspOpts
		local ret = {
			-- options for vim.diagnostic.config()
			---@type vim.diagnostic.Opts
			diagnostics = {
				underline = true,
				update_in_insert = false,
				virtual_text = {
					spacing = 4,
					source = "if_many",
					prefix = "icons",
					-- this will set set the prefix to a function that returns the diagnostics icon based on the severity
					-- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
					-- prefix = "icons",
				},
				severity_sort = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.HINT] = " ",
						[vim.diagnostic.severity.INFO] = " ",
					},
				},
			},
			-- add any global capabilities here
			capabilities = {
				workspace = {
					fileOperations = {
						didRename = true,
						willRename = true,
					},
				},
			},
		}
		return ret
	end,
	---@param opts PluginLspOpts
	config = function(_, opts)
		--INFO: inlay_hint and codelens config
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("my.lsp", {}),
			callback = function(args)
				local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
				local buffer = args.buf
				if
					client:supports_method("textDocument/inlayHint")
					and vim.api.nvim_buf_is_valid(buffer)
					and vim.bo[buffer].buftype == ""
				then
					vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
				end

				if client:supports_method("textDocument/codeLens") then
					vim.lsp.codelens.refresh()
					vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
						buffer = buffer,
						callback = vim.lsp.codelens.refresh,
					})
				end
			end,
		})

		--INFO: diagnostic config
		if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
			opts.diagnostics.virtual_text.prefix = function(diagnostic)
				local icons = {
					Error = " ",
					Warn = " ",
					Hint = " ",
					Info = " ",
				}
				for d, icon in pairs(icons) do
					if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
						return icon
					end
				end
			end
		end
		vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

		-- INFO: clangd config
		vim.lsp.enable("clangd")
		vim.lsp.config("clangd", {
			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--completion-style=detailed",
				"--fallback-style=llvm",
				"--function-arg-placeholders=1",
				"--header-insertion=iwyu",
				"--header-insertion-decorators",
			},
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
			root_markers = {
				".clangd",
				".clang-tidy",
				".clang-format",
				"compile_commands.json",
				"compile_flags.txt",
				"configure.ac", -- AutoTools
				".git",
			},
			capabilities = {
				textDocument = {
					completion = {
						editsNearCursor = true,
					},
				},
				offsetEncoding = { "utf-8", "utf-16" },
			},
			on_attach = function()
				vim.api.nvim_buf_create_user_command(0, "LspClangdSwitchSourceHeader", function()
					switch_source_header(0)
				end, { desc = "Switch between source/header" })

				vim.api.nvim_buf_create_user_command(0, "LspClangdShowSymbolInfo", function()
					symbol_info()
				end, { desc = "Show symbol info" })
			end,
		})

		-- INFO: go config
		vim.lsp.enable("gopls")
		vim.lsp.config("gopls", {
			cmd = { os.getenv("HOME") .. "/go/bin/gopls" },
			filetypes = { "go", "gomod", "gowork", "gotmpl" },
			root_dir = function(bufnr, on_dir)
				local function get_root(fname)
					if mod_cache and fname:sub(1, #mod_cache) == mod_cache then
						local clients = vim.lsp.get_clients({ name = "gopls" })
						if #clients > 0 then
							return clients[#clients].config.root_dir
						end
					end
					return vim.fs.root(fname, "go.work") or vim.fs.root(fname, "go.mod") or vim.fs.root(fname, ".git")
				end

				local fname = vim.api.nvim_buf_get_name(bufnr)
				-- see: https://github.com/neovim/nvim-lspconfig/issues/804
				if mod_cache then
					on_dir(get_root(fname))
					return
				end
				local cmd = { "go", "env", "GOMODCACHE" }
				vim.system(cmd, { text = true }, function(output)
					if output.code == 0 then
						if output.stdout then
							mod_cache = vim.trim(output.stdout)
						end
						on_dir(get_root(fname))
					else
						vim.schedule(function()
							vim.notify(
								("[gopls] cmd failed with code %d: %s\n%s"):format(output.code, cmd, output.stderr)
							)
						end)
					end
				end)
			end,
		})
	end,
}
