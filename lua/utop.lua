local M = {}

local function notif(msg)
  vim.notify("[utop.nvim] " .. msg)
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

local function send(expr)
  if not vim.g.utop.opened then
    notif("utop is not opened")
    return
  end
  vim.api.nvim_chan_send(vim.g.utop.channel, expr .. "\r")
end

---@class UtopOptions
---@field insert_on_open boolean Automatically switch to insert mode when the utop window opens

---@param opts UtopOptions
function M.setup(opts)
  vim.g.utop = {
    insert_on_open = vim.F.if_nil(opts.insert_on_open, true),

    opened = false,
    window = 0,
    buf = 0,
    channel = 0,

    open = open,
    send = send,
  }
end

return M
