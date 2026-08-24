local function fail(message)
  vim.api.nvim_err_writeln("NVF minimal runtime check failed: " .. message)
  vim.cmd("cquit 1")
end

local function command_exists(name)
  return vim.fn.exists(":" .. name) == 2
end

local function require_absent_command(name)
  if command_exists(name) then
    fail("unexpected command exists: " .. name)
  end
end

local function require_absent_keymap(lhs)
  local mapping = vim.fn.maparg(lhs, "n", false, true)
  if mapping and mapping.lhs then
    fail("unexpected normal-mode keymap for " .. lhs .. ": " .. vim.inspect(mapping))
  end
end

if not command_exists("FzfLua") then
  fail("core FzfLua command is missing")
end

local fzf_ok, fzf = pcall(require, "fzf-lua")
if not fzf_ok or type(fzf.files) ~= "function" then
  fail("core fzf-lua module/providers are unavailable")
end

for _, command in ipairs({
  "CodeCompanion",
  "CodeCompanionChat",
  "Obsidian",
  "Trouble",
  "DapContinue",
  "DapToggleBreakpoint",
  "DapTerminate",
  "MarkdownPreview",
}) do
  require_absent_command(command)
end

for _, lhs in ipairs({
  "<leader>lr",
  "<leader>ld",
  "<leader>ls",
  "<leader>lw",
  "<leader>lci",
  "<leader>lco",
  "<leader>la",
  "<leader>lh",
  "<leader>lR",
  "<leader>li",
  "<leader>lt",
  "<leader>xx",
}) do
  require_absent_keymap(lhs)
end

print("NVF_MINIMAL_RUNTIME_OK")
