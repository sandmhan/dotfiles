local function fail(message)
  vim.api.nvim_err_writeln("NVF markdown runtime check failed: " .. message)
  vim.cmd("cquit 1")
end

local function assert_contains(haystack, needle, label)
  if not haystack:find(needle, 1, true) then
    fail(label .. " missing: " .. needle)
  end
end

local function command_exists(name)
  return vim.fn.exists(":" .. name) == 2
end

local function require_command(name)
  if not command_exists(name) then
    fail("missing command: " .. name)
  end
end

local function require_executable(name)
  if vim.fn.executable(name) ~= 1 then
    fail("missing executable on wrapped PATH: " .. name)
  end
end

local function require_keymap(lhs, rhs)
  local leader = vim.g.mapleader or "\\"
  local expanded = lhs:gsub("<leader>", leader)
  for _, candidate in ipairs({ lhs, expanded }) do
    local mapping = vim.fn.maparg(candidate, "n", false, true)
    if mapping and mapping.lhs then
      if rhs and mapping.rhs ~= rhs then
        fail("unexpected rhs for " .. lhs .. ": " .. vim.inspect(mapping))
      end
      return
    end
  end
  fail("missing normal-mode keymap: " .. lhs)
end

local fixture = os.getenv("SANDVIM_MARKDOWN_FIXTURE")
if not fixture or fixture == "" then
  fail("SANDVIM_MARKDOWN_FIXTURE is not set")
end

if vim.api.nvim_buf_get_name(0) ~= fixture then
  vim.cmd("edit " .. vim.fn.fnameescape(fixture))
end
if vim.bo.filetype ~= "markdown" then
  fail("fixture filetype is not markdown: " .. vim.bo.filetype)
end
require_executable("xclip")
require_executable("wl-paste")

local conform_ok, conform = pcall(require, "conform")
if not conform_ok then
  fail("conform.nvim is unavailable")
end
if not conform.list_formatters_for_buffer or not vim.tbl_contains(conform.list_formatters_for_buffer(0), "mdformat") then
  fail("Conform did not register mdformat for markdown buffers")
end
local formatter_info = conform.get_formatter_info("mdformat", 0)
if not formatter_info.available then
  fail("packaged mdformat is unavailable: " .. vim.inspect(formatter_info))
end
local formatted = conform.format({ bufnr = 0, timeout_ms = 60000 })
if formatted == false then
  fail("Conform mdformat formatting failed")
end

vim.cmd("silent write")
local lint_ok, lint = pcall(require, "lint")
if not lint_ok then
  fail("nvim-lint is unavailable")
end
local lint_spec = lint.linters["markdownlint-cli2"]
if
  not lint_spec
  or type(lint_spec.cmd) ~= "string"
  or vim.fn.executable(lint_spec.cmd) ~= 1
  or type(lint_spec.args) ~= "table"
then
  fail("packaged markdownlint-cli2 command is unavailable: " .. vim.inspect(lint_spec))
end
local lint_command = { lint_spec.cmd }
local replaced_stdin = false
for _, arg in ipairs(lint_spec.args) do
  if arg == "-" then
    table.insert(lint_command, fixture)
    replaced_stdin = true
  else
    table.insert(lint_command, arg)
  end
end
if not replaced_stdin then
  fail("markdownlint-cli2 arguments do not contain the expected stdin marker: " .. vim.inspect(lint_spec.args))
end
local lint_output = vim.fn.system(lint_command)
if vim.v.shell_error ~= 0 then
  fail("markdownlint-cli2 rejected the formatted fixture: " .. lint_output)
end
assert_contains(lint_output, "Summary: 0 error(s)", "markdownlint-cli2 result")

lint.try_lint("markdownlint-cli2")
local lint_completed = vim.wait(30000, function()
  return not vim.tbl_contains(lint.get_running(0), "markdownlint-cli2")
end, 100)
if not lint_completed then
  fail("nvim-lint markdownlint-cli2 integration did not complete")
end
local lint_diagnostics = vim.diagnostic.get(0, { namespace = lint.get_namespace("markdownlint-cli2") })
if #lint_diagnostics > 0 then
  fail("nvim-lint reported unexpected Markdown diagnostics: " .. vim.inspect(lint_diagnostics))
end

local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
for _, needle in ipairs({
  "sandvim-phase10-sentinel",
  "- [ ] Verify documentation pack",
  "- [x] Preserve completed task",
  "[[Second Brain]]",
  "![[diagram.png]]",
  "> [!note]",
  "%% Obsidian comment %%",
  "^phase10-block",
  "[^phase10]",
  "```mermaid",
}) do
  assert_contains(text, needle, "formatted Markdown semantics")
end

local markdown_parser = vim.treesitter.get_string_parser(text, "markdown")
markdown_parser:parse()
local inline_parser = vim.treesitter.get_string_parser("[[Second Brain]] and [link](target.md)", "markdown_inline")
inline_parser:parse()

for _, command in ipairs({ "MarkdownPreview", "RenderMarkdown", "Obsidian" }) do
  require_command(command)
end

local render_ok, render_markdown = pcall(require, "render-markdown")
if not render_ok or type(render_markdown.enable) ~= "function" then
  fail("render-markdown.nvim module is unavailable")
end
local render_enable_ok, render_enable_err = pcall(vim.cmd, "RenderMarkdown enable")
if not render_enable_ok then
  fail("RenderMarkdown enable failed: " .. tostring(render_enable_err))
end
local render_disable_ok, render_disable_err = pcall(vim.cmd, "RenderMarkdown disable")
if not render_disable_ok then
  fail("RenderMarkdown disable failed: " .. tostring(render_disable_err))
end

for lhs, rhs in pairs({
  ["<leader>cp"] = "<cmd>MarkdownPreview<cr>",
  ["<leader>uc"] = "<cmd>RenderMarkdown toggle<cr>",
  ["<leader>nn"] = "<cmd>Obsidian new<cr>",
  ["<leader>np"] = "<cmd>Obsidian paste_img<cr>",
  ["<leader>nx"] = "<cmd>Obsidian toggle_checkbox<cr>",
  ["<leader>nT"] = "<cmd>Obsidian template<cr>",
}) do
  require_keymap(lhs, rhs)
end

local task_line
for line_number, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
  if line:find("Verify documentation pack", 1, true) then
    task_line = line_number
    break
  end
end
if not task_line then
  fail("could not find task line for Obsidian toggle_checkbox")
end
vim.api.nvim_win_set_cursor(0, { task_line, 0 })
local obsidian_toggle_ok, obsidian_toggle_err = pcall(vim.cmd, "Obsidian toggle_checkbox")
if not obsidian_toggle_ok then
  fail("Obsidian toggle_checkbox failed: " .. tostring(obsidian_toggle_err))
end
local toggled_line = vim.api.nvim_buf_get_lines(0, task_line - 1, task_line, false)[1]
if not (toggled_line:find("%[x%]") or toggled_line:find("%[~%]")) then
  fail("Obsidian toggle_checkbox did not toggle the task: " .. tostring(toggled_line))
end

local required_clients = {
  harper = false,
  ["markdown-oxide"] = false,
  ["obsidian-ls"] = false,
}
local attached = vim.wait(30000, function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if required_clients[client.name] ~= nil then
      required_clients[client.name] = true
    end
  end
  return required_clients.harper
    and required_clients["markdown-oxide"]
    and required_clients["obsidian-ls"]
end, 100)
if not attached then
  fail("configured documentation LSP clients did not attach: " .. vim.inspect(required_clients))
end

print("NVF_MARKDOWN_RUNTIME_OK")
