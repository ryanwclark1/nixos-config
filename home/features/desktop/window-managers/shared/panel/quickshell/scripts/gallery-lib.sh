#!/usr/bin/env bash

# Shared library for generating QA Matrix galleries with an improved UI/UX.

render_gallery_css() {
  cat <<'EOF'
  <style>
    :root {
      color-scheme: dark;
      --bg: #0f1115;
      --panel: #1a1f29;
      --panel-hover: #222936;
      --border: #2b3342;
      --text: #e6ebf2;
      --muted: #9aa6b2;
      --accent: #7aa2ff;
      --success: #4ade80;
    }

    body {
      margin: 0;
      padding: 0;
      background: var(--bg);
      color: var(--text);
      font: 14px/1.5 'Inter', system-ui, -apple-system, sans-serif;
    }

    header {
      position: sticky;
      top: 0;
      background: rgba(15, 17, 21, 0.9);
      backdrop-filter: blur(12px);
      padding: 16px 24px;
      border-bottom: 1px solid var(--border);
      z-index: 100;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 20px;
    }

    .title-area h1 { margin: 0; font-size: 1.2rem; }
    .title-area p { margin: 4px 0 0; font-size: 0.85rem; color: var(--muted); }

    .controls {
      display: flex;
      gap: 12px;
      flex-grow: 1;
      justify-content: flex-end;
    }

    #filterInput, #jumpTo {
      background: var(--panel);
      border: 1px solid var(--border);
      color: var(--text);
      padding: 8px 12px;
      border-radius: 8px;
      outline: none;
      font-size: 13px;
    }

    #filterInput { width: 250px; }
    #filterInput:focus { border-color: var(--accent); }

    main { padding: 24px; }

    .section { margin-top: 40px; scroll-margin-top: 100px; }
    .section:first-child { margin-top: 0; }
    
    .section-header {
      display: flex;
      align-items: baseline;
      gap: 12px;
      margin-bottom: 16px;
      border-bottom: 1px solid var(--border);
      padding-bottom: 8px;
    }

    .section-header h2 { margin: 0; font-size: 1.1rem; text-transform: uppercase; letter-spacing: 0.05em; color: var(--accent); }
    .section-header .count { color: var(--muted); font-size: 12px; }

    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
      gap: 20px;
    }

    .card {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 12px;
      overflow: hidden;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      position: relative;
    }

    .card:hover {
      transform: translateY(-4px);
      border-color: var(--accent);
      background: var(--panel-hover);
      box-shadow: 0 12px 24px rgba(0,0,0,0.3);
    }

    .card a { display: block; text-decoration: none; color: inherit; }

    .card img {
      display: block;
      width: 100%;
      aspect-ratio: 16/10;
      object-fit: contain;
      background: #000;
      cursor: zoom-in;
    }

    .card .meta { padding: 12px; }

    .card .name { font-weight: 600; font-size: 0.9rem; margin-bottom: 4px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    
    .card .actions {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-top: 12px;
    }

    .btn {
      background: transparent;
      border: 1px solid var(--border);
      color: var(--muted);
      padding: 4px 8px;
      border-radius: 6px;
      cursor: pointer;
      font-size: 11px;
      transition: all 0.2s;
    }

    .btn:hover { background: var(--border); color: var(--text); }
    .btn.active { color: var(--success); border-color: var(--success); }

    .card.reviewed { opacity: 0.6; }
    .card.reviewed::after {
      content: '✓ REVIEWED';
      position: absolute;
      top: 10px;
      right: 10px;
      background: var(--success);
      color: #000;
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 10px;
      font-weight: 700;
      z-index: 10;
    }

    [hidden] { display: none !important; }
  </style>
EOF
}

render_gallery_js() {
  cat <<'EOF'
  <script>
    function filterCards() {
      const query = document.getElementById('filterInput').value.toLowerCase();
      const cards = document.querySelectorAll('.card');
      
      cards.forEach(card => {
        const name = card.getAttribute('data-name').toLowerCase();
        card.hidden = !name.includes(query);
      });
    }

    function copyPath(path, btn) {
      navigator.clipboard.writeText(path);
      const originalText = btn.innerText;
      btn.innerText = 'Copied!';
      btn.style.borderColor = 'var(--accent)';
      setTimeout(() => {
        btn.innerText = originalText;
        btn.style.borderColor = '';
      }, 1500);
    }

    function toggleReviewed(btn) {
      const card = btn.closest('.card');
      card.classList.toggle('reviewed');
      btn.classList.toggle('active');
      btn.innerText = card.classList.contains('reviewed') ? 'Unmark' : 'Mark Reviewed';
    }
  </script>
EOF
}

write_gallery_v2() {
  local output_dir="$1"
  local title="$2"
  local script_name="$3"
  local gallery_path="${output_dir}/index.html"
  local sections=()
  local section_count=0

  # Discover sections
  mapfile -t sections < <(find "${output_dir}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

  {
    cat <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
EOF
    render_gallery_css
    cat <<EOF
</head>
<body>

<header>
  <div class="title-area">
    <h1>${title}</h1>
    <p>Generated by <code>${script_name}</code></p>
  </div>
  
  <div class="controls">
    <input type="text" id="filterInput" placeholder="Filter by filename..." oninput="filterCards()">
EOF
    if (( ${#sections[@]} > 0 )); then
      cat <<EOF
    <select id="jumpTo" onchange="const el = document.getElementById(this.value); if(el) el.scrollIntoView({behavior:'smooth'})">
      <option value="">Jump to section...</option>
EOF
      for s in "${sections[@]}"; do
        printf '      <option value="sec-%s">%s</option>\n' "${s}" "${s}"
      done
      printf '    </select>\n'
    fi
    cat <<EOF
  </div>
</header>

<main>
EOF

    if (( ${#sections[@]} == 0 )); then
      # Flat mode (images in root)
      printf '  <div class="grid">\n'
      while IFS= read -r image_path; do
        rel_image_path="${image_path#${output_dir}/}"
        image_name="$(basename "${image_path}")"
        render_card "${rel_image_path}" "${image_name}"
      done < <(find "${output_dir}" -maxdepth 1 -type f -name '*.png' | sort)
      printf '  </div>\n'
    else
      # Nested mode (directories as sections)
      for s in "${sections[@]}"; do
        local image_count
        image_count=$(find "${output_dir}/${s}" -maxdepth 1 -type f -name '*.png' | wc -l)
        
        printf '  <div class="section" id="sec-%s">\n' "${s}"
        printf '    <div class="section-header">\n'
        printf '      <h2>%s</h2>\n' "${s}"
        printf '      <span class="count">(%s items)</span>\n' "${image_count}"
        printf '    </div>\n'
        printf '    <div class="grid">\n'
        
        while IFS= read -r image_path; do
          rel_image_path="${image_path#${output_dir}/}"
          image_name="$(basename "${image_path}")"
          render_card "${rel_image_path}" "${image_name}"
        done < <(find "${output_dir}/${s}" -maxdepth 1 -type f -name '*.png' | sort)
        
        printf '    </div>\n'
        printf '  </div>\n'
      done
    fi

    cat <<EOF
</main>
EOF
    render_gallery_js
    printf '</body>\n</html>\n'
  } > "${gallery_path}"
}

render_card() {
  local rel_path="$1"
  local name="$2"
  cat <<EOF
      <div class="card" data-name="${name}">
        <a href="${rel_path}" target="_blank">
          <img src="${rel_path}" alt="${name}" loading="lazy">
        </a>
        <div class="meta">
          <div class="name">${name}</div>
          <div class="actions">
            <button class="btn" onclick="copyPath('${rel_path}', this)">Copy Path</button>
            <button class="btn" onclick="toggleReviewed(this)">Mark Reviewed</button>
          </div>
        </div>
      </div>
EOF
}
