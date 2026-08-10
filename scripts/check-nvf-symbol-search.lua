local function fail(message)
  vim.api.nvim_err_writeln("NVF symbol search check failed: " .. message)
  vim.cmd("cquit 1")
end

local function flatten_symbols(items, names)
  names = names or {}
  for _, item in ipairs(items or {}) do
    if item.name then
      names[item.name] = true
    end
    if item.children then
      flatten_symbols(item.children, names)
    end
  end
  return names
end

local function require_map(lhs, expected)
  local mapping = vim.fn.maparg(lhs, "n", false, true)
  local rhs = (mapping.rhs or ""):lower()
  if mapping.buffer ~= 0 or rhs ~= expected:lower() then
    fail(string.format("effective %s mapping mismatch: %s", lhs, vim.inspect(mapping)))
  end
end

if not vim.wait(20000, function()
  return vim.iter(vim.lsp.get_clients({ bufnr = 0 })):any(function(client)
    return client.name == "basedpyright"
  end)
end, 100) then
  fail("basedpyright did not attach within 20 seconds")
end

local basedpyright
for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
  if client.name == "basedpyright" then
    basedpyright = client
    break
  end
end
if not basedpyright then
  fail("basedpyright client missing after readiness wait")
end

local capabilities = basedpyright.server_capabilities
for capability, enabled in pairs({
  documentSymbolProvider = capabilities.documentSymbolProvider,
  workspaceSymbolProvider = capabilities.workspaceSymbolProvider,
  definitionProvider = capabilities.definitionProvider,
  referencesProvider = capabilities.referencesProvider,
  callHierarchyProvider = capabilities.callHierarchyProvider,
}) do
  if not enabled then
    fail("basedpyright lacks " .. capability)
  end
end

require_map("<leader>fs", "<cmd>FzfLua treesitter<cr>")
require_map("<leader>ls", "<cmd>FzfLua lsp_document_symbols<cr>")
require_map("<leader>lw", "<cmd>FzfLua lsp_workspace_symbols<cr>")
require_map("<leader>lr", "<cmd>FzfLua lsp_references<cr>")
require_map("<leader>ld", "<cmd>FzfLua lsp_definitions<cr>")
require_map("<leader>lci", "<cmd>FzfLua lsp_incoming_calls<cr>")
require_map("<leader>lco", "<cmd>FzfLua lsp_outgoing_calls<cr>")

local signature = vim.fn.maparg("<leader>lk", "n", false, true)
if signature.buffer ~= 1 or signature.desc ~= "Signature help" then
  fail("effective <leader>lk is not buffer-local signature help: " .. vim.inspect(signature))
end

local fzf = require("fzf-lua")
for _, provider in ipairs({
  "treesitter",
  "lsp_document_symbols",
  "lsp_workspace_symbols",
  "lsp_incoming_calls",
  "lsp_outgoing_calls",
}) do
  if type(fzf[provider]) ~= "function" then
    fail("missing FzfLua provider: " .. provider)
  end
end

local text_document = vim.lsp.util.make_text_document_params()
local document_responses = vim.lsp.buf_request_sync(
  0,
  "textDocument/documentSymbol",
  { textDocument = text_document },
  10000
)
if not document_responses then
  fail("document symbol request timed out")
end

local document_names = {}
for _, response in pairs(document_responses) do
  if response.result then
    flatten_symbols(response.result, document_names)
  end
end
for _, expected in ipairs({ "Greeter", "greet", "make_message", "top_level" }) do
  if not document_names[expected] then
    fail("document symbols missing " .. expected)
  end
end

local workspace_names = {}
if not vim.wait(20000, function()
  local response = basedpyright:request_sync(
    "workspace/symbol",
    { query = "workspace_helper" },
    5000,
    0
  )
  if response and not response.err then
    workspace_names = flatten_symbols(response.result or {})
  end
  return workspace_names.workspace_helper == true
end, 500) then
  fail("workspace symbols missing workspace_helper after indexing wait")
end

local parser_ok, parser = pcall(vim.treesitter.get_parser, 0, "python")
if not parser_ok or not parser then
  fail("Python Treesitter parser unavailable")
end
if not vim.treesitter.query.get("python", "locals") then
  fail("Python Treesitter locals query unavailable")
end

local function prepare_call_hierarchy(line, character)
  local response = basedpyright:request_sync(
    "textDocument/prepareCallHierarchy",
    {
      textDocument = text_document,
      position = { line = line, character = character },
    },
    10000,
    0
  )
  if not response or response.err or not response.result or not response.result[1] then
    fail(string.format("call hierarchy preparation failed at %d:%d", line, character))
  end
  return response.result[1]
end

local make_message = prepare_call_hierarchy(5, 6)
local incoming = basedpyright:request_sync(
  "callHierarchy/incomingCalls",
  { item = make_message },
  10000,
  0
)
if not incoming or incoming.err then
  fail("incoming call hierarchy request failed")
end
local incoming_names = {}
for _, call in ipairs(incoming.result or {}) do
  if call.from and call.from.name then
    incoming_names[call.from.name] = true
  end
end
if not incoming_names.greet then
  fail("incoming calls for make_message do not include greet")
end

local top_level = prepare_call_hierarchy(9, 6)
local outgoing = basedpyright:request_sync(
  "callHierarchy/outgoingCalls",
  { item = top_level },
  10000,
  0
)
if not outgoing or outgoing.err then
  fail("outgoing call hierarchy request failed")
end
local outgoing_names = {}
for _, call in ipairs(outgoing.result or {}) do
  if call.to and call.to.name then
    outgoing_names[call.to.name] = true
  end
end
if not outgoing_names.Greeter or not outgoing_names.greet then
  fail("outgoing calls for top_level do not include Greeter and greet")
end

print("NVF_SYMBOL_SEARCH_RUNTIME_OK")
