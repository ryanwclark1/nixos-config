import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    SharedWidgets.Ref { service: ForgeService }

    function _statusText(token, status, message, count, countLabel) {
        if (token === "") return "No token configured";
        if (status === "ready") return "Connected — " + count + " " + countLabel;
        if (status === "error") return "Error: " + message;
        if (status === "loading") return "Connecting...";
        return "Idle";
    }

    function _statusColor(status) {
        if (status === "ready") return Colors.primary;
        if (status === "error") return Colors.error;
        return Colors.textSecondary;
    }

    SettingsTabPage {
        anchors.fill: parent
        SettingsPage {
            tabId: root.tabId
            title: "Forge"
            iconName: "brands/github-symbolic.svg"

            SettingsCard {
                title: "GitHub"
                iconName: "brands/github-symbolic.svg"
                description: "Monitor your GitHub notifications directly in the bar."
            SettingsInfoCallout {
                body: "Requires the 'gh' CLI and a Personal Access Token with 'notifications' scope."
            }

            SettingsSecretInputRow {
                label: "Access Token"
                leadingIcon: "key.svg"
                placeholderText: "Enter your GH_TOKEN..."
                text: Config.githubToken
                onTextEdited: value => Config.githubToken = value
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                SettingsActionButton {
                    label: "Test Connection"
                    iconName: "checkmark.svg"
                    enabled: Config.githubToken !== ""
                    onClicked: ForgeService.githubPoll.triggerPoll()
                }

                Text {
                    Layout.fillWidth: true
                    text: root._statusText(Config.githubToken, ForgeService.githubStatus, ForgeService.githubMessage, ForgeService.githubUnreadCount, "unread notifications")
                    color: root._statusColor(ForgeService.githubStatus)
                    font.pixelSize: Appearance.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }

        SettingsCard {
            title: "GitLab"
            iconName: "brands/gitlab.svg"
            description: "Monitor your GitLab todos and notifications."

            SettingsTextInputRow {
                label: "GitLab Host"
                leadingIcon: "server.svg"
                placeholderText: "e.g. gitlab.com or git.example.com"
                text: Config.gitlabHost
                onTextEdited: value => Config.gitlabHost = value
            }

            SettingsSecretInputRow {
                label: "Access Token"
                leadingIcon: "key.svg"
                placeholderText: "Enter your GitLab Personal Access Token..."
                text: Config.gitlabToken
                onTextEdited: value => Config.gitlabToken = value
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                SettingsActionButton {
                    label: "Test Connection"
                    iconName: "checkmark.svg"
                    enabled: Config.gitlabToken !== "" && Config.gitlabHost !== ""
                    onClicked: ForgeService.gitlabPoll.triggerPoll()
                }

                Text {
                    Layout.fillWidth: true
                    text: root._statusText(Config.gitlabToken, ForgeService.gitlabStatus, ForgeService.gitlabMessage, ForgeService.gitlabUnreadCount, "pending todos")
                    color: root._statusColor(ForgeService.gitlabStatus)
                    font.pixelSize: Appearance.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
