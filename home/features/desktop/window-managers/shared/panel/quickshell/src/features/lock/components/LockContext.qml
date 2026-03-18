import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import "../../../services"

QtObject {
  id: root

  readonly property string pamConfigDirectory: "/etc/pam.d"
  property string pamConfig: "login"
  property bool pamReady: false

  property string currentText: ""
  property bool waitingForPassword: false
  property bool unlockInProgress: false
  property string errorMessage: ""
  property bool showError: false

  // Fingerprint auth
  property bool fprintAvailable: false
  property bool fprintActive: false
  property string fprintStatus: ""  // "scanning" | "error" | "max_tries" | ""
  property int _fprintRetries: 0

  signal unlocked()
  signal failed()

  // PAM service auto-detection
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

  // Fingerprint reader detection
  property var _fprintDetectProc: Process {
    command: ["sh", "-c", "fprintd-list \"$1\" 2>/dev/null", "sh", Quickshell.env("USER") || ""]
    stdout: SplitParser {
      onRead: data => {
        // Any output means fprintd-list found enrolled fingerprints
      }
    }
    onExited: (exitCode, exitStatus) => {
      root.fprintAvailable = (exitCode === 0);
      if (root.fprintAvailable && Config.lockScreenFingerprint)
        root._startFprint();
    }
  }

  // Fingerprint PAM context
  property PamContext fprintPam: PamContext {
    configDirectory: root.pamConfigDirectory
    config: "fprintd-verify"

    onPamMessage: {
      // fprintd prompts are informational — no response needed
    }

    onCompleted: result => {
      if (result === PamResult.Success) {
        root.unlocked();
      } else if (result === PamResult.MaxTries && root._fprintRetries < 3) {
        root._fprintRetries++;
        root.fprintStatus = "scanning";
        fprintPam.start();
      } else {
        root.fprintStatus = (result === PamResult.MaxTries) ? "max_tries" : "error";
        root.fprintActive = false;
      }
    }
  }

  function _startFprint() {
    _fprintRetries = 0;
    fprintStatus = "scanning";
    fprintActive = true;
    fprintPam.start();
  }

  Component.onCompleted: {
    _detectProc.running = true;
    _fprintDetectProc.running = true;
  }

  property PamContext pam: PamContext {
    configDirectory: root.pamConfigDirectory
    config: root.pamConfig

    onPamMessage: {
      if (this.responseRequired) {
        if (root.currentText !== "") {
          this.respond(root.currentText);
          root.unlockInProgress = true;
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
        root.unlocked();
      } else {
        root.currentText = "";
        root.errorMessage = "Authentication failed";
        root.showError = true;
        root.failed();
      }
      root.unlockInProgress = false;
      root.waitingForPassword = false;
    }
  }

  function tryUnlock() {
    root.showError = false;
    if (waitingForPassword) {
      pam.respond(currentText);
      unlockInProgress = true;
    } else {
      pam.start();
    }
  }

  function reset() {
    currentText = "";
    errorMessage = "";
    showError = false;
    waitingForPassword = false;
    unlockInProgress = false;
    fprintPam.abort();
    fprintStatus = "";
    fprintActive = false;
  }
}
