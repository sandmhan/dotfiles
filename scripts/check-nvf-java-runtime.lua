local function fail(message)
  vim.api.nvim_err_writeln("NVF Java runtime check failed: " .. message)
  vim.cmd("cquit 1")
end

local function flatten_symbols(items, names)
  names = names or {}
  for _, item in ipairs(items or {}) do
    if item.name then
      names[item.name] = true
      local plain = item.name:match("^([%w_]+)")
      if plain then
        names[plain] = true
      end
    end
    if item.children then
      flatten_symbols(item.children, names)
    end
  end
  return names
end

local function is_jdtls(client)
  local name = (client.name or ""):lower()
  return name == "jdtls" or name == "jdt-language-server" or name:find("jdt", 1, true) ~= nil
end

if vim.fn.executable("astyle") ~= 1 then
  fail("astyle executable is not on the packaged Neovim PATH")
end

if not vim.wait(60000, function()
  return vim.iter(vim.lsp.get_clients({ bufnr = 0 })):any(is_jdtls)
end, 500) then
  local names = vim.tbl_map(function(client)
    return client.name
  end, vim.lsp.get_clients({ bufnr = 0 }))
  fail("JDTLS did not attach within 60 seconds; clients=" .. vim.inspect(names))
end

local jdtls
for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
  if is_jdtls(client) then
    jdtls = client
    break
  end
end
if not jdtls then
  fail("JDTLS client missing after readiness wait")
end

local capabilities = jdtls.server_capabilities or {}
for capability, enabled in pairs({
  documentSymbolProvider = capabilities.documentSymbolProvider,
  definitionProvider = capabilities.definitionProvider,
  referencesProvider = capabilities.referencesProvider,
}) do
  if not enabled then
    fail("JDTLS lacks " .. capability .. "; capabilities=" .. vim.inspect(capabilities))
  end
end

local parser_ok, parser = pcall(vim.treesitter.get_parser, 0, "java")
if not parser_ok or not parser then
  fail("Java Treesitter parser unavailable")
end

local text_document = vim.lsp.util.make_text_document_params(0)
local document_names = {}
if not vim.wait(30000, function()
  local responses = vim.lsp.buf_request_sync(
    0,
    "textDocument/documentSymbol",
    { textDocument = text_document },
    3000
  )
  document_names = {}
  for _, response in pairs(responses or {}) do
    if response.result then
      flatten_symbols(response.result, document_names)
    end
  end
  return document_names.Greeter == true and document_names.greet == true
end, 3000) then
  fail("document symbols missing Greeter/greet after indexing wait: " .. vim.inspect(document_names))
end

print("NVF_JAVA_RUNTIME_OK client=" .. jdtls.name)
