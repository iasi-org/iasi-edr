local current = nil

local function stringify(value)
  if value == nil then
    return nil
  end
  return pandoc.utils.stringify(value)
end

local function span(text, class_name)
  return pandoc.Span(
    { pandoc.Str(text) },
    pandoc.Attr("", { class_name }, {})
  )
end

local function separator()
  return {
    pandoc.Space(),
    pandoc.Str("·"),
    pandoc.Space()
  }
end

local function append(target, values)
  for _, value in ipairs(values) do
    target:insert(value)
  end
end

function Meta(meta)
  local id = stringify(meta.id)

  if id == nil or not id:match("^EDR%-%d%d%d%d%d$") then
    current = nil
    return meta
  end

  current = {
    id = id,
    status = stringify(meta.status),
    created = stringify(meta.created),
    area = nil,
    tags = {}
  }

  if meta.area ~= nil and meta.area.name ~= nil then
    current.area = stringify(meta.area.name)
  end

  if meta.tags ~= nil then
    for _, tag in ipairs(meta.tags) do
      table.insert(current.tags, stringify(tag))
    end
  end

  return meta
end

function Pandoc(doc)
  if current == nil then
    return doc
  end

  local summary = pandoc.Inlines({})
  summary:insert(span(current.id, "edr-id"))

  if current.area ~= nil and current.area ~= "" then
    append(summary, separator())
    summary:insert(span(current.area, "edr-area"))
  end

  if current.status ~= nil and current.status ~= "" then
    append(summary, separator())
    summary:insert(span(current.status, "edr-status"))
  end

  if current.created ~= nil and current.created ~= "" then
    append(summary, separator())
    summary:insert(span(current.created, "edr-created"))
  end

  local blocks = {
    pandoc.Div(
      { pandoc.Plain(summary) },
      pandoc.Attr("", { "edr-meta-summary" }, {})
    )
  }

  if #current.tags > 0 then
    local tags = pandoc.Inlines({
      span("Tags", "edr-tags-label"),
      pandoc.Space()
    })

    for i, tag in ipairs(current.tags) do
      local code = pandoc.Code(tag)
      code.attr = pandoc.Attr("", { "edr-tag" }, {})
      tags:insert(code)
      if i < #current.tags then
        tags:insert(pandoc.Space())
      end
    end

    table.insert(
      blocks,
      pandoc.Div(
        { pandoc.Plain(tags) },
        pandoc.Attr("", { "edr-tags" }, {})
      )
    )
  end

  local meta_block = pandoc.Div(
    blocks,
    pandoc.Attr("", { "edr-meta" }, {})
  )

  table.insert(doc.blocks, 1, meta_block)
  return doc
end

return {
  { Meta = Meta },
  { Pandoc = Pandoc }
}
