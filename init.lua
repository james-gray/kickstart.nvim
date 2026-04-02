-- =============================================================================
-- Neovim Configuration
-- Last updated: 2026-04-02
--
-- Based on kickstart.nvim with custom additions for Python/TypeScript dev.
-- Symlinked from ~/code/kickstart.nvim/init.lua -> ~/.config/nvim/init.lua
--
-- Plugin manager: lazy.nvim (:Lazy to manage, <S-l> shortcut)
-- Completion:     CoC + blink.cmp + LuaSnip
-- LSP:            nvim-lspconfig + mason (pyright, lua_ls)
-- Search:         telescope.nvim + fzf-lua
-- Testing:        neotest (pytest)
-- Theme:          catppuccin (macchiato)
-- File tree:      neo-tree (auto-opens on startup, auto-quits with last pane)
-- AI:             claude-code.nvim, cursor-agent.nvim
-- Refactoring:    refactoring.nvim (ThePrimeagen)
--
-- Keymap quick-reference (leader = <Space>):
--   <leader>f       Find files (fzf)
--   <leader>h       File history (fzf)
--   <leader>s*      Search (telescope): sh=help sk=keymaps sf=files sg=grep sd=diagnostics
--   <leader>t*      Test (neotest): tt=file tT=all tr=nearest td=debug tl=last ts=summary
--   <leader>r*      Refactor: rr=select rx=extract rf=to-file rv=var ri=inline rb=block
--   <leader>r*      CoC refactor: rn=rename re=refactor ra=refactor-selected
--   <leader>a*      CoC actions: a=selected ac=cursor as=source
--   <leader>F       Format buffer (conform)
--   <leader>`       Toggle neo-tree
--   <leader>0v/0h   Terminal (vertical/horizontal split)
--   <leader><Esc>1  Claude Code
--   <leader><Esc>2  Cursor Agent
--   <Tab>/<S-Tab>   vsplit / hsplit
--   `               Window prefix (<C-w>)
--   <C-hjkl>        Navigate splits
--   K               Show docs (CoC)
--   gd/gy/gi/gr     GoTo definition/type/impl/refs (CoC, opens in vsplit)
-- =============================================================================

-- =============================================================================
-- 1. LEADER & GLOBALS
-- =============================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
vim.g.python3_host_prog = "$PYENV_ROOT/shims/python3"
vim.g.root_spec = { "cwd" }

-- =============================================================================
-- 2. OPTIONS
-- =============================================================================

vim.o.number = true
vim.o.mouse = "a"
vim.o.showmode = false
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "yes"
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.o.inccommand = "split"
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true
vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.softtabstop = 4
vim.o.shiftwidth = 4

vim.opt.autochdir = false
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.backup = false
vim.opt.writebackup = false

vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- =============================================================================
-- 3. KEYMAPS (non-plugin)
-- =============================================================================

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Splits
vim.keymap.set("n", "<Tab>", ":vsplit<cr>")
vim.keymap.set("n", "<S-Tab>", ":split<cr>")
vim.keymap.set("n", "`", "<C-w>")
vim.keymap.set("n", "<C-H>", "<C-W><C-H>", { noremap = true, desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-J>", "<C-W><C-J>", { noremap = true, desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-K>", "<C-W><C-K>", { noremap = true, desc = "Move focus to the upper window" })
vim.keymap.set("n", "<C-L>", "<C-W><C-L>", { noremap = true, desc = "Move focus to the right window" })

-- Neo-tree
vim.keymap.set("n", "<leader>`", ":Neotree toggle=true<cr><C-W><C-J>")

-- Terminal
vim.keymap.set("n", "<leader>0v", [[<cmd>vsplit | term<cr>A]], { desc = "Open terminal in vertical split" })
vim.keymap.set("n", "<leader>0h", [[<cmd>split | term<cr>A]], { desc = "Open terminal in horizontal split" })

-- Lazy
vim.keymap.set("n", "<S-l>", ":Lazy<cr>")

-- =============================================================================
-- 4. AUTOCOMMANDS
-- =============================================================================

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Open neo-tree on startup
vim.api.nvim_create_autocmd("VimEnter", {
	callback = vim.schedule_wrap(function()
		vim.cmd("Neotree show")
	end),
})

-- Quit neovim if neo-tree is the only window left
vim.api.nvim_create_autocmd("WinClosed", {
	callback = function()
		vim.schedule(function()
			local dominated_by_sidebar = true
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local buf = vim.api.nvim_win_get_buf(win)
				local ft = vim.bo[buf].filetype
				if ft ~= "neo-tree" and ft ~= "" then
					dominated_by_sidebar = false
					break
				end
			end
			if dominated_by_sidebar then
				vim.cmd("qa")
			end
		end)
	end,
})

-- =============================================================================
-- 5. LAZY.NVIM BOOTSTRAP
-- =============================================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end
---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- =============================================================================
-- 6. PLUGINS
-- =============================================================================

require("lazy").setup({

	-- ── Utilities ──────────────────────────────────────────────────────────
	"NMAC427/guess-indent.nvim",
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	-- ── AI Assistants ─────────────────────────────────────────────────────
	{
		"greggh/claude-code.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("claude-code").setup()
			vim.keymap.set(
				"n",
				"<leader><Esc>1",
				"<cmd>ClaudeCode<CR>",
				{ desc = "Claude Code Agent: Toggle terminal" }
			)
		end,
	},
	{
		"xTacobaco/cursor-agent.nvim",
		config = function()
			vim.keymap.set("n", "<leader><Esc>2", ":CursorAgent<CR>", { desc = "Cursor Agent: Toggle terminal" })
			vim.keymap.set("v", "<leader><Esc>", ":CursorAgentSelection<CR>", { desc = "Cursor Agent: Send selection" })
			vim.keymap.set("n", "<leader><S-Esc>", ":CursorAgentBuffer<CR>", { desc = "Cursor Agent: Send buffer" })
		end,
	},

	-- ── CoC ───────────────────────────────────────────────────────────────
	{ "neoclide/coc.nvim", branch = "release" },

	-- ── TypeScript ────────────────────────────────────────────────────────
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		opts = {},
	},

	-- ── Fuzzy finding ─────────────────────────────────────────────────────
	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			fzf_opts = { ["--history"] = vim.fn.stdpath("data") .. "/fzf-history" },
			files = { no_ignore = true },
		},
		keys = {
			{
				"<leader>f",
				function()
					require("fzf-lua").files()
				end,
				desc = "Find [f]iles fuzzily (fzf)",
			},
			{
				"<leader>h",
				function()
					require("fzf-lua").oldfiles()
				end,
				desc = "Open file [h]istory (fzf)",
			},
		},
	},
	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = { require("telescope.themes").get_dropdown() },
				},
			})
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
			vim.keymap.set("n", "<leader>/", function()
				builtin.current_buffer_fuzzy_find(
					require("telescope.themes").get_dropdown({ winblend = 10, previewer = false })
				)
			end, { desc = "[/] Fuzzily search in current buffer" })
			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({ grep_open_files = true, prompt_title = "Live Grep in Open Files" })
			end, { desc = "[S]earch [/] in Open Files" })
			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},

	-- ── Testing ───────────────────────────────────────────────────────────
	{ "nvim-neotest/neotest-python" },
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"mfussenegger/nvim-dap",
			"mfussenegger/nvim-dap-python",
		},
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-python")({
						dap = { justMyCode = false },
						args = { "-v", "--log-level", "DEBUG" },
						runner = "pytest",
					}),
				},
			})
			require("dap-python").setup()
			require("dap-python").test_runner = "pytest"
		end,
		keys = {
			{ "<leader>t", "", desc = "+test" },
			{
				"<leader>tt",
				function()
					require("neotest").output_panel.clear()
					require("neotest").output_panel.open({ enter = true, auto_close = true })
					require("neotest").run.run(vim.fn.expand("%"))
				end,
				desc = "Run File (Neotest)",
			},
			{
				"<leader>tT",
				function()
					require("neotest").output_panel.clear()
					require("neotest").output_panel.open({ enter = true, auto_close = true })
					require("neotest").summary.open()
					require("neotest").run.run(vim.uv.cwd())
				end,
				desc = "Run All Test Files (Neotest)",
			},
			{
				"<leader>tr",
				function()
					require("neotest").output_panel.clear()
					require("neotest").output_panel.open({ enter = true, auto_close = true })
					require("neotest").run.run()
				end,
				desc = "Run Nearest (Neotest)",
			},
			{
				"<leader>td",
				function()
					require("neotest").run.run({ strategy = "dap" })
				end,
				desc = "Debug (Neotest)",
			},
			{
				"<leader>tl",
				function()
					require("neotest").output_panel.clear()
					require("neotest").output_panel.open({ enter = true, auto_close = true })
					require("neotest").run.run_last()
				end,
				desc = "Run Last (Neotest)",
			},
			{
				"<leader>ts",
				function()
					require("neotest").summary.toggle()
				end,
				desc = "Toggle Summary (Neotest)",
			},
			{
				"<leader>tS",
				function()
					require("neotest").run.stop()
				end,
				desc = "Stop (Neotest)",
			},
		},
	},

	-- ── Git ───────────────────────────────────────────────────────────────
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},

	-- ── Which-key ─────────────────────────────────────────────────────────
	{
		"folke/which-key.nvim",
		event = "VimEnter",
		opts = {
			delay = 0,
			icons = {
				mappings = vim.g.have_nerd_font,
				keys = vim.g.have_nerd_font and {} or {
					Up = "<Up> ",
					Down = "<Down> ",
					Left = "<Left> ",
					Right = "<Right> ",
					C = "<C-…> ",
					M = "<M-…> ",
					D = "<D-…> ",
					S = "<S-…> ",
					CR = "<CR> ",
					Esc = "<Esc> ",
					ScrollWheelDown = "<ScrollWheelDown> ",
					ScrollWheelUp = "<ScrollWheelUp> ",
					NL = "<NL> ",
					BS = "<BS> ",
					Space = "<Space> ",
					Tab = "<Tab> ",
					F1 = "<F1>",
					F2 = "<F2>",
					F3 = "<F3>",
					F4 = "<F4>",
					F5 = "<F5>",
					F6 = "<F6>",
					F7 = "<F7>",
					F8 = "<F8>",
					F9 = "<F9>",
					F10 = "<F10>",
					F11 = "<F11>",
					F12 = "<F12>",
				},
			},
			spec = {
				{ "<leader>s", group = "[S]earch" },
				{ "<leader>t", group = "[T]oggle" },
			},
		},
	},

	-- ── LSP ───────────────────────────────────────────────────────────────
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"saghen/blink.cmp",
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
					map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
					map("grd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
					map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
					map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")
					map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
					map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")

					---@param client vim.lsp.Client
					---@param method vim.lsp.protocol.Method
					---@param bufnr? integer
					---@return boolean
					local function client_supports_method(client, method, bufnr)
						if vim.fn.has("nvim-0.11") == 1 then
							return client:supports_method(method, bufnr)
						else
							return client.supports_method(method, { bufnr = bufnr })
						end
					end

					local client = vim.lsp.get_client_by_id(event.data.client_id)

					-- Highlight references of the word under cursor on CursorHold
					if
						client
						and client_supports_method(
							client,
							vim.lsp.protocol.Methods.textDocument_documentHighlight,
							event.buf
						)
					then
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})
						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					-- Toggle inlay hints
					if
						client
						and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
					then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			-- Diagnostics
			vim.diagnostic.config({
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
				underline = { severity = vim.diagnostic.severity.ERROR },
				signs = vim.g.have_nerd_font and {
					text = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					},
				} or {},
				virtual_text = {
					source = "if_many",
					spacing = 2,
					format = function(diagnostic)
						return diagnostic.message
					end,
				},
			})

			-- LSP capabilities (enhanced by blink.cmp)
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Language servers to install via Mason
			local servers = {
				pyright = {},
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
						},
					},
				},
			}

			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, { "stylua" })
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				ensure_installed = {},
				automatic_installation = false,
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},

	-- ── Formatting ────────────────────────────────────────────────────────
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>F",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				local disable_filetypes = { c = true, cpp = true }
				if disable_filetypes[vim.bo[bufnr].filetype] then
					return nil
				end
				return { timeout_ms = 500, lsp_format = "fallback" }
			end,
			formatters_by_ft = {
				lua = { "stylua" },
			},
		},
	},

	-- ── Autocompletion ────────────────────────────────────────────────────
	{
		"saghen/blink.cmp",
		event = "VimEnter",
		version = "1.*",
		dependencies = {
			{
				"L3MON4D3/LuaSnip",
				version = "2.*",
				build = (vim.fn.has("win32") == 0 and vim.fn.executable("make") == 1) and "make install_jsregexp"
					or nil,
				opts = {},
			},
			"folke/lazydev.nvim",
		},
		--- @module 'blink.cmp'
		--- @type blink.cmp.Config
		opts = {
			keymap = { preset = "default" },
			appearance = { nerd_font_variant = "mono" },
			completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
			sources = {
				default = { "lsp", "path", "snippets", "lazydev" },
				providers = {
					lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
				},
			},
			snippets = { preset = "luasnip" },
			fuzzy = { implementation = "lua" },
			signature = { enabled = true },
		},
	},

	-- ── Theme ─────────────────────────────────────────────────────────────
	{
		"catppuccin/nvim",
		priority = 1000,
		config = function()
			---@diagnostic disable-next-line: missing-fields
			require("catppuccin").setup({
				flavour = "macchiato",
				styles = { comments = { "italic" } },
				integrations = { coc_nvim = true },
				highlight_overrides = {
					all = function(colors)
						return {}
					end,
				},
			})
			vim.cmd.colorscheme("catppuccin")
		end,
	},

	-- ── Editor enhancements ───────────────────────────────────────────────
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.surround").setup()

			local statusline = require("mini.statusline")
			statusline.setup({ use_icons = vim.g.have_nerd_font })
			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_location = function()
				return "%2l:%-2v"
			end
		end,
	},

	-- ── Treesitter ────────────────────────────────────────────────────────
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs",
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
			},
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = { enable = true, disable = { "ruby" } },
		},
	},

	-- ── Refactoring ───────────────────────────────────────────────────────
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
		opts = {},
		keys = {
			{
				"<leader>rr",
				function()
					require("refactoring").select_refactor()
				end,
				mode = { "n", "x" },
				desc = "[R]efactor: select",
			},
			{
				"<leader>rx",
				function()
					return require("refactoring").refactor("Extract Function")
				end,
				mode = "x",
				expr = true,
				desc = "[R]efactor: extract function",
			},
			{
				"<leader>rf",
				function()
					return require("refactoring").refactor("Extract Function To File")
				end,
				mode = "x",
				expr = true,
				desc = "[R]efactor: extract to file",
			},
			{
				"<leader>rv",
				function()
					return require("refactoring").refactor("Extract Variable")
				end,
				mode = "x",
				expr = true,
				desc = "[R]efactor: extract variable",
			},
			{
				"<leader>ri",
				function()
					return require("refactoring").refactor("Inline Variable")
				end,
				mode = { "n", "x" },
				expr = true,
				desc = "[R]efactor: inline variable",
			},
			{
				"<leader>rI",
				function()
					return require("refactoring").refactor("Inline Function")
				end,
				mode = "n",
				expr = true,
				desc = "[R]efactor: inline function",
			},
			{
				"<leader>rb",
				function()
					return require("refactoring").refactor("Extract Block")
				end,
				mode = "n",
				expr = true,
				desc = "[R]efactor: extract block",
			},
			{
				"<leader>rB",
				function()
					return require("refactoring").refactor("Extract Block To File")
				end,
				mode = "n",
				expr = true,
				desc = "[R]efactor: extract block to file",
			},
			{
				"<leader>rp",
				function()
					require("refactoring").debug.printf({ below = false })
				end,
				mode = "n",
				desc = "[R]efactor: debug printf",
			},
			{
				"<leader>rd",
				function()
					require("refactoring").debug.print_var()
				end,
				mode = { "x", "n" },
				desc = "[R]efactor: debug print var",
			},
			{
				"<leader>rc",
				function()
					require("refactoring").debug.cleanup({})
				end,
				mode = "n",
				desc = "[R]efactor: debug cleanup",
			},
		},
	},

	-- ── Kickstart extras ──────────────────────────────────────────────────
	require("kickstart.plugins.debug"),
	require("kickstart.plugins.indent_line"),
	require("kickstart.plugins.lint"),
	require("kickstart.plugins.neo-tree"),
	require("kickstart.plugins.gitsigns"),
}, {
	ui = {
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})

-- =============================================================================
-- 7. COC CONFIGURATION
-- Adapted from: https://github.com/neoclide/coc.nvim/blob/master/doc/coc-example-config.lua
-- =============================================================================

local keyset = vim.keymap.set

-- Completion
function _G.check_back_space()
	local col = vim.fn.col(".") - 1
	return col == 0 or vim.fn.getline("."):sub(col, col):match("%s") ~= nil
end

local coc_completion_opts = { silent = true, noremap = true, expr = true, replace_keycodes = false }
keyset(
	"i",
	"<TAB>",
	'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()',
	coc_completion_opts
)
keyset("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], coc_completion_opts)
keyset(
	"i",
	"<cr>",
	[[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]],
	coc_completion_opts
)
keyset("i", "<c-j>", "<Plug>(coc-snippets-expand-jump)")
keyset("i", "<c-space>", "coc#refresh()", { silent = true, expr = true })

-- Diagnostics navigation
keyset("n", "[g", "<Plug>(coc-diagnostic-prev)", { silent = true })
keyset("n", "]g", "<Plug>(coc-diagnostic-next)", { silent = true })

-- GoTo code navigation (opens in vsplit)
keyset("n", "gd", ":vsp<CR><Plug>(coc-definition)", { silent = true })
keyset("n", "gy", ":vsp<CR><Plug>(coc-type-definition)", { silent = true })
keyset("n", "gi", ":vsp<CR><Plug>(coc-implementation)", { silent = true })
keyset("n", "gr", ":vsp<CR><Plug>(coc-references)", { silent = true })

-- Documentation
function _G.show_docs()
	local cw = vim.fn.expand("<cword>")
	if vim.fn.index({ "vim", "help" }, vim.bo.filetype) >= 0 then
		vim.api.nvim_command("h " .. cw)
	elseif vim.api.nvim_eval("coc#rpc#ready()") then
		vim.fn.CocActionAsync("doHover")
	else
		vim.api.nvim_command("!" .. vim.o.keywordprg .. " " .. cw)
	end
end
keyset("n", "K", "<CMD>lua _G.show_docs()<CR>", { silent = true })

-- Highlight symbol on CursorHold
vim.api.nvim_create_augroup("CocGroup", {})
vim.api.nvim_create_autocmd("CursorHold", {
	group = "CocGroup",
	command = "silent call CocActionAsync('highlight')",
	desc = "Highlight symbol under cursor on CursorHold",
})

-- Rename
keyset("n", "<leader>rn", "<Plug>(coc-rename)", { silent = true })

-- Format expression for TypeScript/JSON
vim.api.nvim_create_autocmd("FileType", {
	group = "CocGroup",
	pattern = "typescript,json",
	command = "setl formatexpr=CocAction('formatSelected')",
})

-- Code actions
local coc_action_opts = { silent = true, nowait = true }
keyset("x", "<leader>a", "<Plug>(coc-codeaction-selected)", coc_action_opts)
keyset("n", "<leader>a", "<Plug>(coc-codeaction-selected)", coc_action_opts)
keyset("n", "<leader>ac", "<Plug>(coc-codeaction-cursor)", coc_action_opts)
keyset("n", "<leader>as", "<Plug>(coc-codeaction-source)", coc_action_opts)
keyset("n", "<leader>qf", "<Plug>(coc-fix-current)", coc_action_opts)

-- Refactor actions (CoC)
keyset("n", "<leader>re", "<Plug>(coc-codeaction-refactor)", { silent = true })
keyset("x", "<leader>ra", "<Plug>(coc-codeaction-refactor-selected)", { silent = true })
keyset("n", "<leader>ra", "<Plug>(coc-codeaction-refactor-selected)", { silent = true })

-- Code Lens
keyset("n", "<leader>cl", "<Plug>(coc-codelens-action)", coc_action_opts)

-- Text objects for functions and classes
keyset("x", "if", "<Plug>(coc-funcobj-i)", coc_action_opts)
keyset("o", "if", "<Plug>(coc-funcobj-i)", coc_action_opts)
keyset("x", "af", "<Plug>(coc-funcobj-a)", coc_action_opts)
keyset("o", "af", "<Plug>(coc-funcobj-a)", coc_action_opts)
keyset("x", "ic", "<Plug>(coc-classobj-i)", coc_action_opts)
keyset("o", "ic", "<Plug>(coc-classobj-i)", coc_action_opts)
keyset("x", "ac", "<Plug>(coc-classobj-a)", coc_action_opts)
keyset("o", "ac", "<Plug>(coc-classobj-a)", coc_action_opts)

-- Scroll float windows
local coc_scroll_opts = { silent = true, nowait = true, expr = true }
keyset("n", "<C-f>", 'coc#float#has_scroll() ? coc#float#scroll(1) : "<C-f>"', coc_scroll_opts)
keyset("n", "<C-b>", 'coc#float#has_scroll() ? coc#float#scroll(0) : "<C-b>"', coc_scroll_opts)
keyset("i", "<C-f>", 'coc#float#has_scroll() ? "<c-r>=coc#float#scroll(1)<cr>" : "<Right>"', coc_scroll_opts)
keyset("i", "<C-b>", 'coc#float#has_scroll() ? "<c-r>=coc#float#scroll(0)<cr>" : "<Left>"', coc_scroll_opts)
keyset("v", "<C-f>", 'coc#float#has_scroll() ? coc#float#scroll(1) : "<C-f>"', coc_scroll_opts)
keyset("v", "<C-b>", 'coc#float#has_scroll() ? coc#float#scroll(0) : "<C-b>"', coc_scroll_opts)

-- Selection ranges
keyset("n", "<C-s>", "<Plug>(coc-range-select)", { silent = true })
keyset("x", "<C-s>", "<Plug>(coc-range-select)", { silent = true })

-- Commands
vim.api.nvim_create_user_command("Format", "call CocAction('format')", {})
vim.api.nvim_create_user_command("Fold", "call CocAction('fold', <f-args>)", { nargs = "?" })
vim.api.nvim_create_user_command("OR", "call CocActionAsync('runCommand', 'editor.action.organizeImport')", {})

-- Statusline integration
vim.opt.statusline:prepend("%{coc#status()}%{get(b:,'coc_current_function','')}")

-- CocList mappings
local coc_list_opts = { silent = true, nowait = true }
keyset("n", "<space>a", ":<C-u>CocList diagnostics<cr>", coc_list_opts)
keyset("n", "<space>e", ":<C-u>CocList extensions<cr>", coc_list_opts)
keyset("n", "<space>c", ":<C-u>CocList commands<cr>", coc_list_opts)
keyset("n", "<space>o", ":<C-u>CocList outline<cr>", coc_list_opts)
keyset("n", "<space>s", ":<C-u>CocList -I symbols<cr>", coc_list_opts)
keyset("n", "<space>j", ":<C-u>CocNext<cr>", coc_list_opts)
keyset("n", "<space>k", ":<C-u>CocPrev<cr>", coc_list_opts)
keyset("n", "<space>p", ":<C-u>CocListResume<cr>", coc_list_opts)
