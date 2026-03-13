import QtQuick
import Quickshell.Io

pragma Singleton

QtObject {
  id: root

  readonly property string catalogPath: String(Qt.resolvedUrl("../plugins/runtime-catalog.json")).replace("file://", "")

  property var states: ({})
  property var errors: ({})

  function reload() {
    var payload = ({ states: ({ }), errors: ({ }) });
    try {
      var raw = catalogFile.text();
      if (raw && String(raw).trim() !== "") {
        var parsed = JSON.parse(raw);
        payload.states = parsed.states && typeof parsed.states === "object" ? parsed.states : ({ });
        payload.errors = parsed.errors && typeof parsed.errors === "object" ? parsed.errors : ({ });
      }
    } catch (e) {
      payload = ({ states: ({ }), errors: ({ }) });
    }
    states = payload.states;
    errors = payload.errors;
  }

  function stateMeta(state) {
    var key = String(state || "");
    if (states[key] && typeof states[key] === "object")
      return states[key];
    return ({ label: key !== "" ? key : "unknown", description: "", severity: "muted" });
  }

  function stateLabel(state) {
    return String(stateMeta(state).label || state || "Unknown");
  }

  function stateSeverity(state) {
    return String(stateMeta(state).severity || "muted");
  }

  function stateDescription(state) {
    return String(stateMeta(state).description || "");
  }

  function errorMeta(code) {
    var key = String(code || "");
    if (errors[key] && typeof errors[key] === "object")
      return errors[key];
    return ({ label: key, severity: "warn" });
  }

  function errorLabel(code) {
    var key = String(code || "");
    if (key === "")
      return "";
    return String(errorMeta(key).label || key);
  }

  function errorSeverity(code) {
    return String(errorMeta(code).severity || "warn");
  }

  function errorDescription(code) {
    return String(errorMeta(code).description || "");
  }

  property FileView catalogFile: FileView {
    path: root.catalogPath
    blockLoading: true
    printErrors: false
    onLoaded: root.reload()
  }

  Component.onCompleted: {
    reload();
  }
}
