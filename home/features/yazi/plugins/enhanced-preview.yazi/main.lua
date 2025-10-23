local M = {}

function M:peek()
  local file = self.file
  local area = self.area

  -- Skip if file is too large (> 10MB)
  if file.len and file.len > 10485760 then
    ya.notify({
      title = "File too large",
      content = "File size exceeds 10MB, preview disabled",
      level = "warn"
    })
    return
  end

  -- Handle different file types with optimized previews
  local mime = file.mime()

  if file.is_dir then
    -- Directory preview with eza
    local child = Command.new("eza")
      :args({ "--tree", "--level=3", "--icons=never", "--color=always" })
      :cwd(file.url)
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :spawn()

    local lines = {}
    local i = 0
    repeat
      local line, event = child:read_line()
      if event ~= 0 and event ~= 1 then break end

      i = i + 1
      if i <= area.h then
        table.insert(lines, line)
      end
    until i >= area.h

    ya.preview_set(lines, area)

  elseif mime:match("^image/") then
    -- Image preview with metadata
    local child = Command.new("exiftool")
      :args({ "-s", "-FileName", "-FileSize", "-ImageSize", "-DateTime", file.url })
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :spawn()

    local metadata = {}
    repeat
      local line, event = child:read_line()
      if event ~= 0 and event ~= 1 then break end
      table.insert(metadata, line)
    until #metadata >= 10

    -- Show image with ueberzug
    ya.image_show(file.url, area)

    -- Overlay metadata
    local metadata_area = ui.Rect({
      x = area.x,
      y = area.y + area.h - 8,
      w = area.w,
      h = 8
    })
    ya.preview_set(metadata, metadata_area)

  elseif mime:match("^text/") or mime == "application/json" then
    -- Text file preview with syntax highlighting
    local child = Command.new("bat")
      :args({
        "--color=always",
        "--paging=never",
        "--style=plain",
        "--wrap=character",
        "--terminal-width=" .. area.w,
        "--line-range=:500",
        file.url
      })
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :spawn()

    local lines = {}
    local i = 0
    repeat
      local line, event = child:read_line()
      if event ~= 0 and event ~= 1 then break end

      i = i + 1
      if i <= area.h then
        table.insert(lines, line)
      end
    until i >= area.h

    ya.preview_set(lines, area)

  elseif mime == "application/pdf" then
    -- PDF preview with poppler
    local child = Command.new("pdftotext")
      :args({ "-layout", "-nopgbrk", file.url, "-" })
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :spawn()

    local lines = {}
    local i = 0
    repeat
      local line, event = child:read_line()
      if event ~= 0 and event ~= 1 then break end

      i = i + 1
      if i <= area.h then
        table.insert(lines, line)
      end
    until i >= area.h

    ya.preview_set(lines, area)

  else
    -- Fallback to file command
    local child = Command.new("file")
      :args({ "-b", file.url })
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :spawn()

    local output = {}
    repeat
      local line, event = child:read_line()
      if event ~= 0 and event ~= 1 then break end
      table.insert(output, line)
    until #output >= 5

    ya.preview_set(output, area)
  end
end

return M
