import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const runtimeWarningsScriptPath = resolve(quickshellRoot, "scripts/check-runtime-warning-regressions.sh");

describe("runtime warning regression script contract", () => {
  it("launches the repo shell from the real src tree", () => {
    const source = readFileSync(runtimeWarningsScriptPath, "utf8");

    expect(source).toContain('config_root="$(CDPATH= cd -- "${script_dir}/../src" >/dev/null && pwd)"');
    expect(source).not.toContain('config_root="$(CDPATH= cd -- "${script_dir}/../config" >/dev/null && pwd)"');
    expect(source).toContain('env "${repo_shell_env[@]}" quickshell -p "${config_root}/shell.qml"');
  });
});
