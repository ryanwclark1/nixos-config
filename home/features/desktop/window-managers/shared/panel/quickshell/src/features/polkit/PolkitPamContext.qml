import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import "../../services"

QtObject {
    id: root

    readonly property string pamConfigDirectory: "/etc/pam.d"
    property string pamConfig: "login"
    property bool pamReady: false

    property string currentText: ""
    property bool waitingForPassword: false
    property bool authInProgress: false
    property string errorMessage: ""
    property bool showError: false

    signal authenticated()
    signal failed()

    // PAM service auto-detection (same as LockContext)
    property var _detectProc: Process {
        command: ["sh", "-c",
            "if [ -f /etc/pam.d/login ]; then echo 'login'; exit 0; fi; " +
            "if [ -f /etc/pam.d/system-auth ]; then echo 'system-auth'; exit 0; fi; " +
            "if [ -f /etc/pam.d/common-auth ]; then echo 'common-auth'; exit 0; fi; " +
            "echo 'login';"
        ]
        stdout: SplitParser {
            onRead: data => {
                var service = (data || "").trim();
                if (service.length > 0) root.pamConfig = service;
                root.pamReady = true;
            }
        }
    }

    Component.onCompleted: {
        _detectProc.running = true;
    }

    property PamContext pam: PamContext {
        configDirectory: root.pamConfigDirectory
        config: root.pamConfig

        onPamMessage: {
            if (this.responseRequired) {
                if (root.currentText !== "") {
                    this.respond(root.currentText);
                    root.authInProgress = true;
                } else {
                    root.waitingForPassword = true;
                }
            } else if (messageIsError) {
                root.errorMessage = message;
                root.showError = true;
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.authenticated();
            } else {
                root.currentText = "";
                root.errorMessage = "Authentication failed";
                root.showError = true;
                root.failed();
            }
            root.authInProgress = false;
            root.waitingForPassword = false;
        }
    }

    function tryAuth() {
        showError = false;
        if (waitingForPassword) {
            pam.respond(currentText);
            authInProgress = true;
        } else {
            pam.start();
        }
    }

    function reset() {
        currentText = "";
        errorMessage = "";
        showError = false;
        waitingForPassword = false;
        authInProgress = false;
    }
}
