local M = {}

local function notif(msg)
  vim.notify("[utop.nvim] " .. msg)
end

local function send(expr)
  if not vim.g.utop.opened then
    notif("utop is not opened")
    return
  end
  vim.api.nvim_chan_send(vim.g.utop.channel, expr .. "\r")
end

local function operator_handler(mode)
  if mode == "" or mode == nil then
    vim.o.opfunc = "v:lua.vim.g.utop._operator_handler"
    return "g@"
  end

  if mode == "block" then
    return
  end

  local reg_save = vim.fn.getreg('"')
  local commands = {
    line = "'[V']",
    char = "`[v`]",
  }

  local cmd = commands[mode] .. '""y'

  vim.fn.execute('noautocmd keepjumps normal!' .. cmd, 'silent')
  local text = vim.fn.getreg('"')

  if vim.g.utop.opened then
    send(text .. ";;")
  end

  vim.fn.setreg('"', reg_save)
end

local function on_exit()
  local g = vim.g.utop

  vim.api.nvim_win_close(g.window, true)
  vim.api.nvim_buf_delete(g.buf, { force = true })

  g.window = 0
  g.term_buf = 0
  g.opened = false

  vim.g.utop = g
end

local function open()
  local g = vim.g.utop

  if g.opened then
    return
  end

  local bufnr = vim.fn.bufnr()
  local expr = "v:lua.vim.g.utop._operator_handler()"
  local opts = { silent = true, expr = true }
  vim.api.nvim_buf_set_keymap(bufnr, "n", g.evaluate_keybind, expr, opts)
  vim.api.nvim_buf_set_keymap(bufnr, "v", g.evaluate_keybind, expr, opts)

  if vim.fn.exepath("utop") == "" then
    notif("utop not found in PATH. please install it to use this plugin")
  end

  g.buf = vim.api.nvim_create_buf(false, true)
  g.window = vim.api.nvim_open_win(g.buf, true, { split = "right" })
  vim.opt_local.number = false
  vim.opt_local.cursorcolumn = false

  g.channel = vim.fn.termopen("utop", { on_exit = on_exit })

  -- Conviniently handle <esc> to go into normal mode
  vim.api.nvim_buf_set_keymap(g.buf, "t", "<esc>", "", {
    noremap = true,
    callback = function()
      vim.cmd('stopinsert')
    end
  })

  if g.insert_on_open then
    vim.cmd('startinsert')
  end

  g.opened = true
  vim.g.utop = g
end


---@class UtopOptions
---@field insert_on_open boolean Automatically switch to insert mode when the utop window opens
---@field evaluate_keybind string Operator mapping which will evaluate the selected expression in utop
---@field open_keybing string? Keybind which opens the opam window

---@param opts UtopOptions
function M.setup(opts)
  vim.g.utop = {
    insert_on_open = vim.F.if_nil(opts.insert_on_open, true),
    evaluate_keybind = vim.F.if_nil(opts.evaluate_keybind, "<leader>v"),

    opened = false,
    window = 0,
    buf = 0,
    channel = 0,

    open = open,
    send = send,
    _operator_handler = operator_handler,
  }

  if opts.open_keybing ~= nil then
    vim.api.nvim_set_keymap("n", opts.open_keybing, ""
    , {
      silent = true,
      callback = function()
        open()
      end
    })
  end
end

return M
