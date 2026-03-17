.pragma library

function stripComments(line) {
  var result = "";
  var quote = "";
  var escaped = false;
  for (var i = 0; i < line.length; ++i) {
    var ch = line.charAt(i);
    if (escaped) {
      result += ch;
      escaped = false;
      continue;
    }
    if (ch === "\\") {
      result += ch;
      escaped = true;
      continue;
    }
    if ((ch === "\"" || ch === "'") && quote === "") {
      quote = ch;
      result += ch;
      continue;
    }
    if (ch === quote) {
      quote = "";
      result += ch;
      continue;
    }
    if (ch === "#" && quote === "")
      break;
    result += ch;
  }
  return result;
}

function splitKeywordValue(line) {
  var trimmed = String(line || "").trim();
  if (trimmed === "")
    return null;
  var quote = "";
  var escaped = false;
  var splitAt = -1;
  for (var i = 0; i < trimmed.length; ++i) {
    var ch = trimmed.charAt(i);
    if (escaped) {
      escaped = false;
      continue;
    }
    if (ch === "\\") {
      escaped = true;
      continue;
    }
    if ((ch === "\"" || ch === "'") && quote === "") {
      quote = ch;
      continue;
    }
    if (ch === quote) {
      quote = "";
      continue;
    }
    if (quote !== "")
      continue;
    if (ch === "=" || /\s/.test(ch)) {
      splitAt = i;
      break;
    }
  }
  if (splitAt === -1)
    return { key: trimmed, value: "" };
  var key = trimmed.slice(0, splitAt).trim();
  var value = trimmed.slice(splitAt + 1).trim();
  if (trimmed.charAt(splitAt) !== "=")
    value = trimmed.slice(splitAt).trim();
  if (value.charAt(0) === "=")
    value = value.slice(1).trim();
  return { key: key, value: value };
}

function tokenize(raw) {
  var text = String(raw || "");
  var out = [];
  var current = "";
  var quote = "";
  var escaped = false;
  for (var i = 0; i < text.length; ++i) {
    var ch = text.charAt(i);
    if (escaped) {
      current += ch;
      escaped = false;
      continue;
    }
    if (ch === "\\") {
      escaped = true;
      continue;
    }
    if ((ch === "\"" || ch === "'") && quote === "") {
      quote = ch;
      continue;
    }
    if (ch === quote) {
      quote = "";
      continue;
    }
    if (quote === "" && /\s/.test(ch)) {
      if (current !== "") {
        out.push(current);
        current = "";
      }
      continue;
    }
    current += ch;
  }
  if (current !== "")
    out.push(current);
  return out;
}

function hasWildcard(token) {
  var text = String(token || "");
  return text.indexOf("*") !== -1 || text.indexOf("?") !== -1 || text.indexOf("[") !== -1 || text.indexOf("]") !== -1;
}

function isExactAlias(token) {
  var text = String(token || "").trim();
  if (text === "" || text.charAt(0) === "!")
    return false;
  return !hasWildcard(text);
}

function coercePort(value) {
  var num = Number(String(value || "").trim());
  return isFinite(num) && num > 0 ? Math.round(num) : 22;
}

function parseFile(text, filePath) {
  var result = {
    includes: [],
    aliases: [],
    skippedPatterns: [],
    matchBlocks: [],
    errors: []
  };
  var lines = String(text || "").replace(/\r\n/g, "\n").split("\n");
  var currentHost = null;
  var currentMatch = null;

  function finalizeHost() {
    if (!currentHost)
      return;
    for (var i = 0; i < currentHost.patterns.length; ++i) {
      var token = String(currentHost.patterns[i] || "").trim();
      if (token === "")
        continue;
      if (!isExactAlias(token)) {
        result.skippedPatterns.push({
          alias: token,
          sourcePath: currentHost.sourcePath,
          sourceLine: currentHost.sourceLine
        });
        continue;
      }
      result.aliases.push({
        alias: token,
        label: token,
        hostName: String(currentHost.options.hostname || ""),
        user: String(currentHost.options.user || ""),
        port: coercePort(currentHost.options.port),
        identityFile: String(currentHost.options.identityfile || ""),
        proxyJump: String(currentHost.options.proxyjump || ""),
        sourcePath: currentHost.sourcePath,
        sourceLine: currentHost.sourceLine
      });
    }
    currentHost = null;
  }

  function finalizeMatch() {
    if (!currentMatch)
      return;
    result.matchBlocks.push({
      conditions: currentMatch.conditions.slice(),
      sourcePath: currentMatch.sourcePath,
      sourceLine: currentMatch.sourceLine
    });
    currentMatch = null;
  }

  for (var lineIndex = 0; lineIndex < lines.length; ++lineIndex) {
    var rawLine = lines[lineIndex];
    var cleaned = stripComments(rawLine).trim();
    if (cleaned === "")
      continue;

    var pair = splitKeywordValue(cleaned);
    if (!pair || String(pair.key || "").trim() === "") {
      result.errors.push({
        path: filePath,
        line: lineIndex + 1,
        message: "Malformed ssh-config line."
      });
      continue;
    }

    var key = String(pair.key || "").trim().toLowerCase();
    var value = String(pair.value || "");
    var tokens = tokenize(value);

    if (key === "host") {
      finalizeHost();
      finalizeMatch();
      currentHost = {
        patterns: tokens,
        options: {},
        sourcePath: filePath,
        sourceLine: lineIndex + 1
      };
      continue;
    }

    if (key === "match") {
      finalizeHost();
      finalizeMatch();
      currentMatch = {
        conditions: tokens,
        sourcePath: filePath,
        sourceLine: lineIndex + 1
      };
      continue;
    }

    if (key === "include") {
      for (var incIdx = 0; incIdx < tokens.length; ++incIdx) {
        var pattern = String(tokens[incIdx] || "").trim();
        if (pattern === "")
          continue;
        result.includes.push({
          pattern: pattern,
          sourcePath: filePath,
          sourceLine: lineIndex + 1
        });
      }
      continue;
    }

    if (currentHost && currentHost.options[key] === undefined)
      currentHost.options[key] = tokens.join(" ");
  }

  finalizeHost();
  finalizeMatch();
  return result;
}

if (typeof module !== "undefined") {
  module.exports = {
    stripComments: stripComments,
    splitKeywordValue: splitKeywordValue,
    tokenize: tokenize,
    hasWildcard: hasWildcard,
    isExactAlias: isExactAlias,
    parseFile: parseFile
  };
}
