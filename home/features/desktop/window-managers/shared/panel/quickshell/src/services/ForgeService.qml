pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "ShellUtils.js" as SU

QtObject {
    id: root

    property int subscriberCount: 0
    property int pollIntervalMs: 300000 // 5 minutes

    property var githubNotifications: []
    property string githubStatus: "idle"
    property string githubMessage: ""
    property int githubUnreadCount: 0

    property var gitlabNotifications: []
    property string gitlabStatus: "idle"
    property string gitlabMessage: ""
    property int gitlabUnreadCount: 0

    readonly property bool hasUnread: githubUnreadCount > 0 || gitlabUnreadCount > 0
    readonly property int totalUnread: githubUnreadCount + gitlabUnreadCount

    function refresh() {
        githubPoll.triggerPoll();
        gitlabPoll.triggerPoll();
    }

    property CommandPoll githubPoll: CommandPoll {
        id: githubPoll
        interval: root.pollIntervalMs
        running: root.subscriberCount > 0 && Config.githubToken !== ""
        command: ["sh", "-c", "if ! command -v gh >/dev/null 2>&1; then printf '__STATUS__\\tmissing\\tgh CLI not found\\n'; exit 0; fi; " +
                              "if ! output=$(GH_TOKEN=\"$1\" gh api notifications --per-page 50 2>/dev/null); then printf '__STATUS__\\terror\\tGitHub API error\\n'; exit 0; fi; " +
                              "printf '__STATUS__\\tready\\t\\n'; printf '%s\\n' \"$output\"", "sh", Config.githubToken]
        onUpdated: {
            var raw = githubPoll.output.trim();
            if (raw.indexOf("__STATUS__\t") === 0) {
                var parts = raw.split("\n")[0].split("\t");
                root.githubStatus = parts[1];
                root.githubMessage = parts[2] || "";
                if (root.githubStatus !== "ready") return;
                raw = raw.substring(raw.indexOf("\n") + 1);
            }

            try {
                var data = JSON.parse(raw);
                root.githubNotifications = data;
                root.githubUnreadCount = data.length;
                root.githubStatus = "ready";
            } catch (e) {
                root.githubStatus = "error";
                root.githubMessage = "Failed to parse GitHub JSON";
            }
        }
    }

    property CommandPoll gitlabPoll: CommandPoll {
        id: gitlabPoll
        interval: root.pollIntervalMs
        running: root.subscriberCount > 0 && Config.gitlabToken !== "" && Config.gitlabHost !== ""
        command: ["sh", "-c", "if ! command -v curl >/dev/null 2>&1; then printf '__STATUS__\\tmissing\\tcurl not found\\n'; exit 0; fi; " +
                              "if ! output=$(curl -s --header \"PRIVATE-TOKEN: $1\" \"https://$2/api/v4/todos?per_page=50\"); then printf '__STATUS__\\terror\\tGitLab API error\\n'; exit 0; fi; " +
                              "printf '__STATUS__\\tready\\t\\n'; printf '%s\\n' \"$output\"", "sh", Config.gitlabToken, Config.gitlabHost]
        onUpdated: {
            var raw = gitlabPoll.output.trim();
            if (raw.indexOf("__STATUS__\t") === 0) {
                var parts = raw.split("\n")[0].split("\t");
                root.gitlabStatus = parts[1];
                root.gitlabMessage = parts[2] || "";
                if (root.gitlabStatus !== "ready") return;
                raw = raw.substring(raw.indexOf("\n") + 1);
            }

            try {
                var data = JSON.parse(raw);
                root.gitlabNotifications = data;
                root.gitlabUnreadCount = data.length;
                root.gitlabStatus = "ready";
            } catch (e) {
                root.gitlabStatus = "error";
                root.gitlabMessage = "Failed to parse GitLab JSON";
            }
        }
    }
}
