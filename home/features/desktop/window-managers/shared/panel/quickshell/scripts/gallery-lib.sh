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
      --warning: #facc15;
      --error: #f87171;
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

    .card .img-container { position: relative; background: #000; aspect-ratio: 16/10; overflow: hidden; cursor: zoom-in; }
    .card img {
      display: block;
      width: 100%;
      height: 100%;
      object-fit: contain;
    }
    .card .baseline-img {
      position: absolute;
      top: 0; left: 0;
      opacity: 0;
      pointer-events: none;
    }
    .card.comparing-diff .baseline-img { opacity: 1; mix-blend-mode: difference; }
    .card.viewing-baseline .baseline-img { opacity: 1; pointer-events: auto; }
    .card.viewing-baseline .current-img { opacity: 0; }

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
    .btn.accent { background: var(--accent); color: #000; border-color: var(--accent); }
    .btn.warn { border-color: var(--warning); color: var(--warning); }

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

    .badge {
      position: absolute;
      top: 10px;
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 10px;
      font-weight: 700;
      z-index: 10;
      display: none;
    }
    .diff-badge { left: 10px; background: var(--warning); color: #000; }
    .failure-badge { left: 10px; background: var(--error); color: white; }
    
    .card.has-diff .diff-badge { display: block; }
    .card.capture-failure .failure-badge { display: block; }
    .card.capture-failure .diff-badge { display: none; }

    /* Lightbox */
    #lightbox {
      position: fixed;
      top: 0; left: 0; width: 100%; height: 100%;
      background: rgba(0,0,0,0.95);
      z-index: 2000;
      display: none;
      align-items: center;
      justify-content: center;
      backdrop-filter: blur(10px);
    }
    #lightbox img { max-width: 90%; max-height: 90%; object-fit: contain; box-shadow: 0 0 50px rgba(0,0,0,0.5); }
    .lightbox-close { position: absolute; top: 20px; right: 30px; font-size: 40px; cursor: pointer; color: var(--muted); }
    .lightbox-nav { position: absolute; top: 50%; width: 100%; display: flex; justify-content: space-between; padding: 0 40px; box-sizing: border-box; pointer-events: none; }
    .lightbox-nav button { pointer-events: auto; background: rgba(255,255,255,0.1); border: none; color: white; padding: 20px; cursor: pointer; border-radius: 50%; font-size: 24px; }

    /* Checklist Sidebar */
    #checklistSidebar {
      position: fixed;
      right: -400px;
      top: 0;
      width: 420px;
      height: 100vh;
      background: var(--panel);
      border-left: 1px solid var(--border);
      z-index: 1000;
      transition: right 0.3s ease;
      display: flex;
      flex-direction: column;
      box-shadow: -10px 0 30px rgba(0,0,0,0.5);
    }
    #checklistSidebar.open { right: 0; }
    .checklist-header {
      padding: 20px;
      border-bottom: 1px solid var(--border);
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .checklist-content {
      padding: 20px;
      overflow-y: auto;
      flex-grow: 1;
    }
    .checklist-item {
      display: flex;
      gap: 12px;
      margin-bottom: 12px;
      align-items: flex-start;
      cursor: pointer;
    }
    .checklist-item input { margin-top: 4px; }
    .checklist-item span { font-size: 0.9rem; }
    .checklist-category {
      font-weight: 700;
      color: var(--accent);
      margin: 20px 0 10px;
      text-transform: uppercase;
      font-size: 0.8rem;
    }
    .checklist-item .run-btn {
      margin-left: auto;
      padding: 2px 6px;
      font-size: 10px;
      background: rgba(122, 162, 255, 0.1);
      border: 1px solid var(--accent);
      color: var(--accent);
      border-radius: 4px;
      cursor: pointer;
    }
    .checklist-item .run-btn:hover { background: var(--accent); color: #000; }

    /* Health Status */
    .health-badge {
      padding: 4px 10px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
    .health-healthy { background: rgba(74, 222, 128, 0.1); color: var(--success); border: 1px solid var(--success); }
    .health-warning { background: rgba(250, 204, 21, 0.1); color: var(--warning); border: 1px solid var(--warning); }
    .health-error { background: rgba(248, 113, 113, 0.1); color: var(--error); border: 1px solid var(--error); }

    .health-section {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 32px;
    }
    .incident-list { margin-top: 16px; display: flex; flex-direction: column; gap: 8px; }
    .incident-item {
      background: var(--bg);
      border-left: 4px solid var(--error);
      padding: 10px 16px;
      border-radius: 4px;
      font-size: 0.9rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .incident-item.warning { border-left-color: var(--warning); }
    .incident-signature { font-family: monospace; font-weight: 600; }

    /* Progress UI */
    .progress-container {
      margin-left: auto;
      display: flex;
      align-items: center;
      gap: 12px;
      font-size: 12px;
      color: var(--muted);
    }
    .progress-bar {
      width: 120px;
      height: 6px;
      background: var(--border);
      border-radius: 3px;
      overflow: hidden;
    }
    .progress-fill {
      height: 100%;
      background: var(--success);
      width: 0%;
      transition: width 0.3s ease;
    }

    .meta-tag {
      font-family: monospace;
      font-size: 10px;
      background: var(--border);
      padding: 2px 6px;
      border-radius: 4px;
      color: var(--muted);
    }

    [hidden] { display: none !important; }
  </style>
EOF
}

render_gallery_js() {
  cat <<'EOF'
  <script>
    let currentLightboxIdx = -1;
    let lightboxImages = [];

    function filterCards() {
      const query = document.getElementById('filterInput').value.toLowerCase();
      const showOnlyDiff = document.getElementById('diffFilter')?.classList.contains('active');
      const cards = document.querySelectorAll('.card');
      
      cards.forEach(card => {
        const name = card.getAttribute('data-name').toLowerCase();
        let visible = name.includes(query);
        if (showOnlyDiff && !card.classList.contains('has-diff')) visible = false;
        card.hidden = !visible;
      });
      updateLightboxImages();
    }

    function toggleDiffFilter(btn) {
      btn.classList.toggle('active');
      btn.innerText = btn.classList.contains('active') ? 'Showing Only Diffs' : 'Filter by Diff';
      filterCards();
    }

    async function validateAndDetect() {
      const cards = document.querySelectorAll('.card');
      for (const card of cards) {
        const currentImg = card.querySelector('.current-img');
        const baselineImg = card.querySelector('.baseline-img');
        
        // Check for blank screen / capture failure
        const isFailure = await checkCaptureFailure(currentImg.src);
        if (isFailure) {
          card.classList.add('capture-failure');
          continue;
        }

        if (!baselineImg) continue;

        const hasDiff = await compareImages(currentImg.src, baselineImg.src);
        if (hasDiff) {
          card.classList.add('has-diff');
        }
      }
    }

    function checkCaptureFailure(src) {
      return new Promise((resolve) => {
        const img = new Image();
        img.crossOrigin = "anonymous";
        img.onload = () => {
          const canvas = document.createElement('canvas');
          const ctx = canvas.getContext('2d');
          canvas.width = img.width;
          canvas.height = img.height;
          ctx.drawImage(img, 0, 0);
          const data = ctx.getImageData(0, 0, img.width, img.height).data;
          
          let blackPixels = 0;
          let totalPixels = data.length / 4;
          for (let i = 0; i < data.length; i += 4) {
            if (data[i] < 10 && data[i+1] < 10 && data[i+2] < 10) blackPixels++;
          }
          // If > 98% pixels are black, it's likely a capture failure
          resolve((blackPixels / totalPixels) > 0.98);
        };
        img.src = src;
      });
    }

    function compareImages(src1, src2) {
      return new Promise((resolve) => {
        const img1 = new Image();
        const img2 = new Image();
        let loaded = 0;
        const onload = () => {
          if (++loaded === 2) {
            if (img1.width !== img2.width || img1.height !== img2.height) return resolve(true);
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            canvas.width = img1.width;
            canvas.height = img1.height;
            ctx.drawImage(img1, 0, 0);
            const data1 = ctx.getImageData(0, 0, img1.width, img1.height).data;
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            ctx.drawImage(img2, 0, 0);
            const data2 = ctx.getImageData(0, 0, img2.width, img2.height).data;
            for (let i = 0; i < data1.length; i += 4) {
              if (Math.abs(data1[i] - data2[i]) > 5 || 
                  Math.abs(data1[i+1] - data2[i+1]) > 5 || 
                  Math.abs(data1[i+2] - data2[i+2]) > 5) {
                return resolve(true);
              }
            }
            resolve(false);
          }
        };
        img1.crossOrigin = "anonymous";
        img2.crossOrigin = "anonymous";
        img1.onload = onload;
        img2.onload = onload;
        img1.src = src1;
        img2.src = src2;
      });
    }

    function copyText(text, btn) {
      navigator.clipboard.writeText(text);
      const originalText = btn.innerText;
      btn.innerText = 'Copied!';
      btn.classList.add('active');
      setTimeout(() => {
        btn.innerText = originalText;
        btn.classList.remove('active');
      }, 1500);
    }

    function toggleReviewed(btn) {
      const card = btn.closest('.card');
      card.classList.toggle('reviewed');
      btn.classList.toggle('active');
      btn.innerText = card.classList.contains('reviewed') ? 'Unmark' : 'Mark Reviewed';
      
      const states = JSON.parse(localStorage.getItem('quickshell-qa-reviewed') || '{}');
      const pageId = document.title + location.pathname;
      if (!states[pageId]) states[pageId] = {};
      states[pageId][card.getAttribute('data-name')] = card.classList.contains('reviewed');
      localStorage.setItem('quickshell-qa-reviewed', JSON.stringify(states));
      
      updateProgress();
    }

    function cycleCompare(btn) {
      const card = btn.closest('.card');
      const states = ['none', 'baseline', 'diff'];
      let currentIdx = states.indexOf(card.getAttribute('data-compare-state') || 'none');
      let nextIdx = (currentIdx + 1) % states.length;
      let nextState = states[nextIdx];
      
      card.setAttribute('data-compare-state', nextState);
      card.classList.remove('viewing-baseline', 'comparing-diff');
      
      if (nextState === 'baseline') {
        card.classList.add('viewing-baseline');
        btn.innerText = 'Viewing Baseline';
        btn.classList.add('accent');
      } else if (nextState === 'diff') {
        card.classList.add('comparing-diff');
        btn.innerText = 'Viewing Diff';
        btn.classList.add('accent');
      } else {
        btn.innerText = 'Compare Baseline';
        btn.classList.remove('accent');
      }
    }

    function toggleChecklist() {
      document.getElementById('checklistSidebar').classList.toggle('open');
    }

    function saveChecklist() {
      const states = {};
      document.querySelectorAll('.checklist-content input').forEach((cb, i) => {
        states[i] = cb.checked;
      });
      localStorage.setItem('quickshell-qa-checklist', JSON.stringify(states));
    }

    function loadChecklist() {
      const states = JSON.parse(localStorage.getItem('quickshell-qa-checklist') || '{}');
      document.querySelectorAll('.checklist-content input').forEach((cb, i) => {
        if (states[i]) cb.checked = true;
      });
    }

    function updateProgress() {
      const cards = document.querySelectorAll('.card');
      if (cards.length === 0) return;
      const reviewed = document.querySelectorAll('.card.reviewed').length;
      const percent = Math.round((reviewed / cards.length) * 100);
      
      const fill = document.querySelector('.progress-fill');
      const text = document.querySelector('.progress-text');
      if (fill) fill.style.width = percent + '%';
      if (text) text.innerText = `${reviewed} / ${cards.length} reviewed (${percent}%)`;
    }

    function loadReviewed() {
      const states = JSON.parse(localStorage.getItem('quickshell-qa-reviewed') || '{}');
      const pageId = document.title + location.pathname;
      const pageStates = states[pageId] || {};
      
      document.querySelectorAll('.card').forEach(card => {
        const name = card.getAttribute('data-name');
        if (pageStates[name]) {
          card.classList.add('reviewed');
          const btn = card.querySelector('button[onclick="toggleReviewed(this)"]');
          if (btn) {
            btn.classList.add('active');
            btn.innerText = 'Unmark';
          }
        }
      });
      updateProgress();
    }

    function updateLightboxImages() {
      lightboxImages = Array.from(document.querySelectorAll('.card:not([hidden]) .current-img')).map(img => img.src);
    }

    function openLightbox(src) {
      updateLightboxImages();
      currentLightboxIdx = lightboxImages.indexOf(src);
      const lb = document.getElementById('lightbox');
      lb.querySelector('img').src = src;
      lb.style.display = 'flex';
    }

    function closeLightbox() {
      document.getElementById('lightbox').style.display = 'none';
    }

    function navigateLightbox(dir) {
      currentLightboxIdx = (currentLightboxIdx + dir + lightboxImages.length) % lightboxImages.length;
      document.getElementById('lightbox').querySelector('img').src = lightboxImages[currentLightboxIdx];
    }

    function exportReport() {
      const cards = document.querySelectorAll('.card');
      const reviewed = document.querySelectorAll('.card.reviewed').length;
      const failures = document.querySelectorAll('.card.capture-failure').length;
      const diffs = document.querySelectorAll('.card.has-diff').length;
      const checklist = document.querySelectorAll('.checklist-content input');
      const checked = Array.from(checklist).filter(c => c.checked).length;
      
      let md = `# QA Pass Report: ${document.title}\n\n`;
      md += `**Visual Matrix:** ${reviewed}/${cards.length} reviewed\n`;
      if (diffs > 0) md += `**Regressions:** ${diffs} detected ⚠️\n`;
      if (failures > 0) md += `**Capture Failures:** ${failures} detected ❌\n`;
      md += `**Checklist:** ${checked}/${checklist.length} tasks completed\n\n`;
      
      if (checked < checklist.length) {
        md += `### Pending Tasks\n`;
        checklist.forEach(c => {
          if (!c.checked) md += `- [ ] ${c.nextElementSibling.innerText}\n`;
        });
      }

      navigator.clipboard.writeText(md);
      alert('PR Report copied to clipboard!');
    }

    function runChecklistCommand(cmd, btn) {
      navigator.clipboard.writeText(cmd);
      const originalText = btn.innerText;
      btn.innerText = 'Copied to run!';
      setTimeout(() => btn.innerText = originalText, 1500);
    }

    window.addEventListener('keydown', (e) => {
      const lb = document.getElementById('lightbox');
      if (lb.style.display === 'flex') {
        if (e.key === 'Escape') closeLightbox();
        if (e.key === 'ArrowLeft') navigateLightbox(-1);
        if (e.key === 'ArrowRight') navigateLightbox(1);
      } else {
        if (e.key === 'f' && e.target.tagName !== 'INPUT') {
          e.preventDefault();
          document.getElementById('filterInput')?.focus();
        }
        if (e.key === 'c' && e.target.tagName !== 'INPUT') toggleChecklist();
      }
    });

    window.addEventListener('DOMContentLoaded', () => {
      loadChecklist();
      loadReviewed();
      updateLightboxImages();
      validateAndDetect();
    });
  </script>
EOF
}

write_gallery_v2() {
  local output_dir="$1"
  local title="$2"
  local script_name="$3"
  local gallery_path="${output_dir}/index.html"
  local sections=()
  local baseline_dir="${output_dir}/baselines"

  # Discover sections
  mapfile -t sections < <(find "${output_dir}" -mindepth 1 -maxdepth 1 -type d -not -name "baselines" -printf '%f\n' | sort)

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

<div id="lightbox" onclick="if(event.target === this) closeLightbox()">
  <span class="lightbox-close" onclick="closeLightbox()">&times;</span>
  <div class="lightbox-nav">
    <button onclick="navigateLightbox(-1)">&lsaquo;</button>
    <button onclick="navigateLightbox(1)">&rsaquo;</button>
  </div>
  <img src="" alt="Lightbox">
</div>

<header>
  <div class="title-area">
    <h1>${title}</h1>
    <p>Generated by <code>${script_name}</code></p>
  </div>
  
  <div class="progress-container">
    <span class="progress-text">0 / 0 reviewed (0%)</span>
    <div class="progress-bar"><div class="progress-fill"></div></div>
    <button class="btn" onclick="exportReport()">Export PR Report</button>
  </div>

  <div class="controls">
    <button id="diffFilter" class="btn" onclick="toggleDiffFilter(this)">Filter by Diff</button>
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
      printf '  <div class="grid">\n'
      while IFS= read -r image_path; do
        rel_image_path="${image_path#${output_dir}/}"
        image_name="$(basename "${image_path}")"
        local baseline_path=""
        [[ -f "${baseline_dir}/${image_name}" ]] && baseline_path="baselines/${image_name}"
        render_card "${rel_image_path}" "${image_name}" "${baseline_path}" ""
      done < <(find "${output_dir}" -maxdepth 1 -type f -name '*.png' | sort)
      printf '  </div>\n'
    else
      for s in "${sections[@]}"; do
        local image_count=$(find "${output_dir}/${s}" -maxdepth 1 -type f -name '*.png' | wc -l)
        printf '  <div class="section" id="sec-%s">\n' "${s}"
        printf '    <div class="section-header"><h2>%s</h2><span class="count">(%s items)</span></div>\n' "${s}" "${image_count}"
        printf '    <div class="grid">\n'
        while IFS= read -r image_path; do
          rel_image_path="${image_path#${output_dir}/}"
          image_name="$(basename "${image_path}")"
          local baseline_path=""
          [[ -f "${baseline_dir}/${rel_image_path}" ]] && baseline_path="baselines/${rel_image_path}"
          render_card "${rel_image_path}" "${image_name}" "${baseline_path}" ""
        done < <(find "${output_dir}/${s}" -maxdepth 1 -type f -name '*.png' | sort)
        printf '    </div></div>\n'
      done
    fi
    printf '</main>\n'
    render_gallery_js
    printf '</body></html>\n'
  } > "${gallery_path}"
}

write_master_index() {
  local output_dir="$1"
  local title="$2"
  local checklist_md="$3"
  local health_json="${4:-{}}"
  local gallery_path="${output_dir}/index.html"
  shift 4
  local links=("$@")

  local health_status=$(echo "${health_json}" | jq -r '.status // "unknown"')
  local health_class="health-error"
  local health_icon="❌"
  case "${health_status}" in
    healthy) health_class="health-healthy"; health_icon="✓" ;;
    safe_fix_pending|manual_review_required) health_class="health-warning"; health_icon="⚠️" ;;
  esac

  local git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  local git_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

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
  <style>
    .dashboard-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px; margin-top: 20px; }
    .db-card { background: var(--panel); border: 1px solid var(--border); border-radius: 16px; padding: 32px; text-align: center; text-decoration: none; color: inherit; transition: all 0.2s; display: flex; flex-direction: column; align-items: center; gap: 16px; }
    .db-card:hover { border-color: var(--accent); transform: translateY(-4px); background: var(--panel-hover); }
    .db-card h3 { margin: 0; font-size: 1.4rem; color: var(--accent); }
    .db-card p { margin: 0; color: var(--muted); font-size: 0.9rem; }
    .db-icon { font-size: 32px; background: rgba(122, 162, 255, 0.1); width: 64px; height: 64px; display: flex; align-items: center; justify-content: center; border-radius: 12px; color: var(--accent); }
  </style>
</head>
<body>
<div id="checklistSidebar">
  <div class="checklist-header">
    <h2 style="margin:0; font-size:1.1rem;">Manual Checklist</h2>
    <button class="btn" onclick="toggleChecklist()">Close</button>
  </div>
  <div class="checklist-content">
EOF
    echo "${checklist_md}" | while IFS= read -r line; do
      if [[ "${line}" =~ ^##\ Recommended\ Interactive\ Commands ]]; then
        in_commands=1
        continue
      fi
      if [[ "${line}" =~ ^##\ (.*) ]]; then
        printf '    <div class="checklist-category">%s</div>\n' "${BASH_REMATCH[1]}"
        in_commands=0
      elif [[ "${line}" =~ ^-\ (.*) ]]; then
        printf '    <label class="checklist-item"><input type="checkbox" onchange="saveChecklist()"><span>%s</span></label>\n' "${BASH_REMATCH[1]}"
      elif [[ "${in_commands}" == 1 && "${line}" =~ ^\`(quickshell\ ipc\ call\ .*)\` ]]; then
        local cmd="${BASH_REMATCH[1]}"
        printf '    <div class="checklist-item"><span style="font-family:monospace; font-size:11px; color:var(--muted);">%s</span> <button class="run-btn" onclick="runChecklistCommand('\''%s'\'', this)">Copy & Run</button></div>\n' "${cmd}" "${cmd}"
      fi
    done
    cat <<EOF
  </div>
</div>
<header>
  <div class="title-area">
    <h1>${title}</h1>
    <p style="display:flex; gap:8px; align-items:center;">
      <span class="meta-tag"> ${git_branch} (${git_hash})</span>
      &bull; 
      <span class="health-badge ${health_class}">${health_icon} System ${health_status}</span>
    </p>
  </div>
  <div class="progress-container">
    <button class="btn" onclick="exportReport()">Export PR Report</button>
    <button class="toggle-checklist-btn" onclick="toggleChecklist()">📋 View Checklist</button>
  </div>
</header>
<main>
EOF
    if [[ "${health_status}" != "healthy" && "${health_status}" != "unknown" ]]; then
      printf '  <div class="health-section"><h3 style="margin:0 0 12px; font-size:1rem; color:var(--error);">Active Health Incidents</h3><div class="incident-list">\n'
      echo "${health_json}" | jq -r '.active_signatures[]' | while IFS= read -r sig; do
        printf '      <div class="incident-item"><div><span class="incident-signature">%s</span></div></div>\n' "${sig}"
      done
      printf '    </div></div>\n'
    fi
    printf '  <div class="dashboard-grid">\n'
    for link in "${links[@]}"; do
      local label="${link%%|*}" path="${link#*|}" icon="📊"
      case "${label,,}" in *launcher*) icon="🚀" ;; *settings*) icon="⚙️" ;; *surface*) icon="🖼️" ;; *panel*) icon="📟" ;; esac
      printf '    <a href="%s" class="db-card"><div class="db-icon">%s</div><h3>%s</h3><p>View visual regression artifacts</p></a>\n' "${path}" "${icon}" "${label}"
    done
    printf '  </div></main>\n'
    render_gallery_js
    printf '</body></html>\n'
  } > "${gallery_path}"
}

render_card() {
  local rel_path="$1" name="$2" baseline_path="$3" repro_cmd="${4:-}"
  cat <<EOF
      <div class="card" data-name="${name}">
        <div class="badge diff-badge">⚠️ DIFF DETECTED</div>
        <div class="badge failure-badge">❌ CAPTURE FAILURE</div>
        <div class="img-container" onclick="openLightbox(this.querySelector('.current-img').src)">
          <img src="${rel_path}" class="current-img" alt="${name}" loading="lazy">
EOF
  if [[ -n "${baseline_path}" ]]; then
    cat <<EOF
          <img src="${baseline_path}" class="baseline-img" alt="Baseline">
EOF
  fi
  cat <<EOF
        </div>
        <div class="meta">
          <div class="name">${name}</div>
          <div class="actions">
            <div style="display: flex; gap: 4px;">
              <button class="btn" onclick="copyText('${rel_path}', this)">Copy Path</button>
EOF
  if [[ -n "${repro_cmd}" ]]; then
    cat <<EOF
              <button class="btn" onclick="copyText('\`${repro_cmd}\`', this)">Repro</button>
EOF
  fi
  cat <<EOF
            </div>
            <div style="display: flex; gap: 4px;">
EOF
  if [[ -n "${baseline_path}" ]]; then
    cat <<EOF
              <button class="btn" onclick="cycleCompare(this)">Compare Baseline</button>
EOF
  fi
  cat <<EOF
              <button class="btn" onclick="toggleReviewed(this)">Mark Reviewed</button>
            </div>
          </div>
        </div>
      </div>
EOF
}
