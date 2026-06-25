{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  codexHome = "${config.home.homeDirectory}/.codex";
  agentDeskContext = builtins.readFile ../shared/agent-desk-context.md;
  mcpConfig = import ../shared/mcp-config.nix { inherit config pkgs lib; };
  mcpServersNix = import inputs.mcp-servers-nix { inherit pkgs; };
  python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
  codexMcpConfig = mcpServersNix.lib.mkConfig pkgs (
    mcpConfig
    // {
      flavor = "codex";
      format = "toml";
      fileName = "mcp-servers.toml";
    }
  );
  mergeCodexMcpServers = pkgs.writeText "merge-codex-mcp-servers.py" ''
    import sys
    from pathlib import Path

    import tomlkit

    config_path = Path(sys.argv[1])
    managed_mcp_path = Path(sys.argv[2])

    if config_path.exists() and config_path.read_text().strip():
        config = tomlkit.parse(config_path.read_text())
    else:
        config = tomlkit.document()

    managed = tomlkit.parse(managed_mcp_path.read_text())
    managed_servers = managed.get("mcp_servers", tomlkit.table())

    # mcp-servers-nix currently emits `headers`; Codex 0.142 expects
    # `http_headers` / `env_http_headers` and denies unknown fields.
    for server in managed_servers.values():
        if not hasattr(server, "pop"):
            continue
        headers = server.pop("headers", None)
        if headers is not None and len(headers) > 0 and "http_headers" not in server:
            server["http_headers"] = headers

    config["mcp_servers"] = managed_servers
    config_path.parent.mkdir(parents=True, exist_ok=True)
    config_path.write_text(tomlkit.dumps(config))
  '';
in
{
  home.packages = [
    pkgs.codex
  ];

  home.file."${codexHome}/AGENT_DESK.md".text = agentDeskContext;
  home.file."${codexHome}/mcp-servers.toml".source = codexMcpConfig;
  home.activation.mergeCodexMcpServers =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${python}/bin/python ${mergeCodexMcpServers} "${codexHome}/config.toml" "${codexMcpConfig}"
    '';
  home.file."${codexHome}/AGENTS.md" = {
    force = true;
    text = ''
      ${agentDeskContext}

      ## Codex Role

      Codex is the validation, review, and alternate-implementation agent.

      Default to:

      - Reviewing Claude/OpenCode changes for bugs and regressions
      - Producing alternate implementation strategies
      - Checking tests, type checks, builds, and stack-specific evaluations
      - Keeping edits scoped to the active Beads item or Gastown workflow stage

      Prefer direct file references, concrete commands, and small patch sets.
    '';
  };

  home.shellAliases = {
    codex-review = "codex";
  };
}
