-- ===== Leader & globals (must come before plugins load) =====
vim.loader.enable()
vim.g.mapleader = ' '
vim.g.c_syntax_for_h = 1 -- treat .h files as C, not C++

-- ===== Options =====  See `:h vim.o`
vim.o.number = true
-- vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.list = true
vim.o.confirm = true
vim.o.wrap = false
vim.o.undofile = true
vim.o.updatetime = 250
vim.o.signcolumn = 'yes'
vim.o.winborder = 'rounded'
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.colorcolumn = '100'
vim.o.swapfile = false
vim.opt.clipboard = 'unnamedplus'

-- 4-space indentation (tab width left at its default of 8)
vim.o.tabstop = 8
vim.o.shiftwidth = 4
vim.o.softtabstop = -1 -- follow shiftwidth
vim.o.expandtab = true

-- ===== Keymaps =====  See `:h vim.keymap.set()`
vim.keymap.set('n', '<leader>w', '<cmd>write<cr>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>q', '<cmd>quitall<cr>', { desc = 'Exit vim' })

-- Window navigation with Alt + h/j/k/l (works from normal, insert, and terminal)
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>')
vim.keymap.set({ 't', 'i' }, '<A-h>', '<C-\\><C-n><C-w>h')
vim.keymap.set({ 't', 'i' }, '<A-j>', '<C-\\><C-n><C-w>j')
vim.keymap.set({ 't', 'i' }, '<A-k>', '<C-\\><C-n><C-w>k')
vim.keymap.set({ 't', 'i' }, '<A-l>', '<C-\\><C-n><C-w>l')
vim.keymap.set('n', '<A-h>', '<C-w>h')
vim.keymap.set('n', '<A-j>', '<C-w>j')
vim.keymap.set('n', '<A-k>', '<C-w>k')
vim.keymap.set('n', '<A-l>', '<C-w>l')

-- ===== Autocommands =====
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight on yank',
    callback = function() vim.hl.on_yank() end,
})
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'markdown', 'text' },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.breakindent = true
    end,
})

-- Open this config quickly with :Config
vim.api.nvim_create_user_command('Config', 'edit ~/.config/nvim/init.lua', {})

-- Clear search highlights when pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<cr>')

-- ===== Plugins =====  See `:h vim.pack`
vim.pack.add({
    { src = 'https://github.com/nvim-mini/mini.nvim' }, -- icons, pairs, files, pick, extra, diff
    { src = 'https://github.com/romus204/tree-sitter-manager.nvim' }, -- parsers
    { src = 'https://github.com/NMAC427/guess-indent.nvim' }, -- auto-detect indentation
    { src = 'https://github.com/loctvl842/monokai-pro.nvim' }, -- colorscheme
})

-- Icons (used by mini.files and mini.pick)
require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()

-- Auto-close brackets, parens, quotes, etc.
require('mini.pairs').setup()

-- Git diff signs in the gutter (mini.diff; reference text = Git index by default).
-- style = 'sign' keeps the familiar gutter signs; mini.diff would otherwise color
-- line numbers because `number` is on. Remove that line to use line-number coloring.
require('mini.diff').setup({
    view = { style = 'sign' },
})

require('mini.statusline').setup()

-- Detect the project root of the current file (nearest VCS ancestor),
-- falling back to the file's own directory. Shared by the explorer and picker.
local function project_root()
    local name = vim.api.nvim_buf_get_name(0)
    local start = vim.fn.getcwd()
    if name:match('^minifiles://') then
        start = name:gsub('^minifiles://%d+', '') -- path mini.files is showing
    elseif name ~= '' then
        start = vim.fs.dirname(name)
    end
    return vim.fs.root(start, { '.git', '.hg', '.svn', '.jj' }) or start
end

-- File explorer: mini.files, anchored at the project root (toggle with <leader>e)
require('mini.files').setup({
    mappings = {
        close = '<ESC>',
    },
})
vim.keymap.set('n', '<leader>e', function()
    MiniFiles.open(project_root())
end, { desc = 'File explorer (project root)' })

-- Fuzzy finder: mini.pick (+ mini.extra for the current-buffer picker).
-- File/grep pickers are scoped to the project root.
-- Needs ripgrep (rg) on your PATH for the files / grep pickers.
require('mini.pick').setup()
require('mini.extra').setup()
vim.ui.select = MiniPick.ui_select -- route vim.ui.select prompts through mini.pick

vim.keymap.set('n', '<leader>sf', function()
    MiniPick.builtin.files(nil, { source = { cwd = project_root() } })
end, { desc = 'Search files' })
vim.keymap.set('n', '<leader>sg', function()
    MiniPick.builtin.grep_live({}, { source = { cwd = project_root() } })
end, { desc = 'Search by grep' })
vim.keymap.set('n', '<leader>sw', function()
    MiniPick.builtin.grep({ pattern = vim.fn.expand('<cword>') }, { source = { cwd = project_root() } })
end, { desc = 'Search current word' })
vim.keymap.set('n', '<leader>sh', MiniPick.builtin.help, { desc = 'Search help' })
vim.keymap.set('n', '<leader>sr', MiniPick.builtin.resume, { desc = 'Resume last picker' })
vim.keymap.set('n', '<leader><leader>', MiniPick.builtin.buffers, { desc = 'Find open buffers' })
vim.keymap.set('n', '<leader>/', function()
    MiniExtra.pickers.buf_lines({ scope = 'current' })
end, { desc = 'Fuzzy search current buffer' })

-- Auto-detect indentation style from file content
require('guess-indent').setup({
    on_tab_options = {
        ["expandtab"] = false,
        ["shiftwidth"] = 0,
    },
})

require('tree-sitter-manager').setup({
    ensure_installed = {
        'bash', 'c', 'cpp', 'diff', 'html', 'lua', 'luadoc',
        'markdown', 'markdown_inline', 'python', 'query', 'vim', 'vimdoc',
    },
    auto_install = true,
})

require('monokai-pro').setup({
    filter = 'spectrum',
    override_palette = function(filter)
        return { text = '#ffffff' }
    end,
    override = function(scheme)
        local p, o = scheme.base, {}

        local function set(groups, opts)
            for _, g in ipairs(groups) do o[g] = opts end
        end

        set({
            '@function.call', '@function.method.call', '@method.call',
            '@function.builtin.lua', '@function.builtin',
            '@constructor',
            '@variable', '@variable.member', '@variable.parameter',
            '@property', '@field',
            '@operator', '@punctuation', '@punctuation.delimiter',
            '@punctuation.bracket', '@punctuation.special',
            'MiniFilesFile'
        }, { fg = p.white })

        set({
            '@type.definition',
        }, { fg = p.cyan })

        set({
            '@keyword.function', '@keyword.type'
        }, { fg = p.red })

        set ({
            '@label',
        }, { fg = p.blue })

        set({ 'Added',   '@diff.plus',  'MiniDiffSignAdd'    }, { fg = p.green  })
        set({ 'Changed', '@diff.delta', 'MiniDiffSignChange' }, { fg = p.yellow })
        set({ 'Removed', '@diff.minus', 'MiniDiffSignDelete' }, { fg = p.red    })
        set({ '@string.escape', '@character.special', 'SpecialChar' }, { fg = p.blue }) -- p.blue = orange

        -- Directory / folder icon (mini.files)
        o['Directory'] = { fg = p.cyan, bg = 'NONE' }
        o['MiniIconsAzure'] = { fg = p.cyan }
        o['MiniPickNormal'] = { fg = p.white }
        o['MiniStarterSection'] = { fg = p.cyan }
        o['NonText'] = { fg = p.dimmed4 }
        o['CurSearch'] = { fg = p.black, bg = p.yellow }
        o['MiniFilesNormal'] = { link = 'Normal' }

        -- Override language specific inconsistencies
        o['@operator.cpp'] = { link = '@operator' }
        o['@type.cpp'] = { link = '@type' }
        return o
    end
})
vim.cmd.colorscheme('monokai-pro-spectrum')
