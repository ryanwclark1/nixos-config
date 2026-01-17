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
    -- Try to use freedesktop thumbnail first (reuses thumbnails from other apps)
    -- This leverages the freedesktop.org thumbnail standard for cross-app compatibility
    local cache_home = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
    local file_uri = "file://" .. tostring(file.url)

    -- Generate MD5 hash of file URI (freedesktop standard)
    local hash_cmd = Command.new("bash")
      :args({ "-c", "echo -n '" .. file_uri .. "' | md5sum | cut -d' ' -f1" })
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :spawn()

    local file_hash = ""
    local hash_line = hash_cmd:read_line()
    if hash_line then
      file_hash = hash_line:gsub("\n", ""):gsub("^%s+", ""):gsub("%s+$", "")
    end
    hash_cmd:start_kill()

    -- Determine thumbnail size based on preview area (freedesktop standard sizes)
    local max_dim = math.max(area.w, area.h)
    local size_name, size_px = "xx-large", "1024"
    if max_dim <= 128 then
      size_name, size_px = "normal", "128"
    elseif max_dim <= 256 then
      size_name, size_px = "large", "256"
    elseif max_dim <= 512 then
      size_name, size_px = "x-large", "512"
    end

    -- Check for existing freedesktop thumbnail
    local thumb_path = cache_home .. "/thumbnails/" .. size_name .. "/" .. file_hash .. ".png"
    local image_path = tostring(file.url)

    -- Use thumbnail if it exists and is newer than source file
    if file_hash ~= "" then
      local check_thumb = Command.new("test")
        :args({ "-f", thumb_path, "-a", "-nt", tostring(file.url), thumb_path })
        :spawn()
      local thumb_status = check_thumb:wait()
      if thumb_status and thumb_status:code() == 0 then
        image_path = thumb_path
      end
    end

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

    -- Show image with ueberzug (using thumbnail if available, otherwise original)
    ya.image_show(Url(image_path), area)

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
