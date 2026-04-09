import { describe, it, expect } from "vitest";
import {
  defaultSshWidgetInstance,
  findFirstWidgetInstance,
  toggleAccordionSection,
  summarizeSshSessions,
  formatSshHostSummary,
  formatSshActivitySummary,
  formatDockerActivitySummary,
} from "../../src/features/system/sections/DevOpsSectionHelpers.js";

describe("defaultSshWidgetInstance", () => {
  it("returns ssh defaults for fallback menu wiring", () => {
    expect(defaultSshWidgetInstance()).toEqual({
      widgetType: "ssh",
      settings: {
        manualHosts: [],
        enableSshConfigImport: true,
        displayMode: "count",
        defaultAction: "connect",
        sshCommand: "ssh",
        showWhenEmpty: false,
        emptyClickAction: "menu",
        emptyLabel: "SSH",
        state: {
          lastConnectedId: "",
          lastConnectedLabel: "",
          lastConnectedAt: "",
          recentIds: [],
        },
      },
    });
  });
});

describe("findFirstWidgetInstance", () => {
  it("returns the first widget instance matching the requested type", () => {
    const bars = [{ id: "top" }, { id: "bottom" }];
    const widgets = {
      top: {
        left: [{ widgetType: "clock", instanceId: "c1" }],
        right: [{ widgetType: "ssh", instanceId: "ssh-1" }],
      },
      bottom: {
        left: [{ widgetType: "ssh", instanceId: "ssh-2" }],
        right: [],
      },
    };

    const result = findFirstWidgetInstance(
      bars,
      (bar, section) => widgets[bar.id][section] || [],
      "ssh",
      { instanceId: "fallback" },
    );

    expect(result).toEqual({ widgetType: "ssh", instanceId: "ssh-1" });
  });

  it("returns the fallback when no widget is found", () => {
    const fallback = { instanceId: "fallback" };
    expect(findFirstWidgetInstance([], () => [], "ssh", fallback)).toBe(fallback);
  });
});

describe("toggleAccordionSection", () => {
  it("opens a closed section", () => {
    expect(toggleAccordionSection("", "docker")).toBe("docker");
  });

  it("closes the active section when clicked again", () => {
    expect(toggleAccordionSection("docker", "docker")).toBe("");
  });

  it("switches between sections", () => {
    expect(toggleAccordionSection("docker", "ssh")).toBe("ssh");
  });
});

describe("summarizeSshSessions", () => {
  it("aggregates duplicate session types and preserves expected ordering", () => {
    const result = summarizeSshSessions([
      { type: "ssh", count: 2 },
      { type: "sftp", count: 1 },
      { type: "ssh", count: 1 },
      { type: "rsync", count: 3 },
    ]);

    expect(result.total).toBe(7);
    expect(result.byType).toEqual({
      ssh: 3,
      sftp: 1,
      rsync: 3,
    });
    expect(result.parts).toEqual([
      "3 SSH",
      "1 SFTP",
      "3 RSYNC",
    ]);
  });

  it("normalizes invalid counts to one", () => {
    const result = summarizeSshSessions([{ type: "ssh", count: 0 }]);
    expect(result.total).toBe(1);
    expect(result.parts).toEqual(["1 SSH"]);
  });
});

describe("summary formatters", () => {
  it("formats SSH host counts from configured hosts", () => {
    expect(formatSshHostSummary(0)).toBe("0 SSH Hosts");
    expect(formatSshHostSummary(1)).toBe("1 SSH Host");
    expect(formatSshHostSummary(4)).toBe("4 SSH Hosts");
  });

  it("formats SSH activity from live sessions", () => {
    expect(formatSshActivitySummary([])).toBe("No active sessions");
    expect(formatSshActivitySummary([{ type: "ssh", count: 2 }, { type: "sftp", count: 1 }])).toBe("2 SSH · 1 SFTP");
  });

  it("formats Docker activity from container state", () => {
    expect(formatDockerActivitySummary([])).toBe("No containers detected");
    expect(formatDockerActivitySummary([{ state: "running" }, { state: "exited" }, { state: "running" }])).toBe("2 running · 1 stopped");
    expect(formatDockerActivitySummary([{ state: "running" }])).toBe("1 running");
  });
});
