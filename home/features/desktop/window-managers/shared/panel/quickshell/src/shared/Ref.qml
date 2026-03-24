import QtQuick

QtObject {
  required property QtObject service
  property bool active: true
  property string subscriptionMode: "detailed"
  property QtObject _subscribedService: null
  property string _subscriptionKind: ""
  readonly property bool _supportsSubscriptionCount: service && service.subscriberCount !== undefined
  readonly property bool _supportsSummarySubscription: service
    && service.addSummarySubscriber !== undefined
    && service.removeSummarySubscriber !== undefined

  function desiredSubscriptionKind(targetService) {
    if (!active || !targetService)
      return "";
    if (subscriptionMode === "summary" && _supportsSummarySubscription)
      return "summary";
    if (targetService.subscriberCount !== undefined)
      return "detailed";
    return "";
  }

  function subscribe(targetService, kind) {
    if (!targetService || kind === "")
      return;
    if (kind === "summary")
      targetService.addSummarySubscriber();
    else
      targetService.subscriberCount++;
  }

  function unsubscribe(targetService, kind) {
    if (!targetService || kind === "")
      return;
    if (kind === "summary")
      targetService.removeSummarySubscriber();
    else
      targetService.subscriberCount--;
  }

  function syncSubscription() {
    var nextService = service;
    var nextKind = desiredSubscriptionKind(nextService);
    var currentService = _subscribedService;
    var currentKind = _subscriptionKind;

    if (currentKind !== "" && (currentService !== nextService || currentKind !== nextKind)) {
      unsubscribe(currentService, currentKind);
      _subscribedService = null;
      _subscriptionKind = "";
    }

    if (_subscriptionKind === "" && nextKind !== "") {
      subscribe(nextService, nextKind);
      _subscribedService = nextService;
      _subscriptionKind = nextKind;
    }
  }

  onServiceChanged: syncSubscription()
  onActiveChanged: syncSubscription()
  onSubscriptionModeChanged: syncSubscription()
  Component.onCompleted: syncSubscription()
  Component.onDestruction: {
    if (_subscriptionKind === "")
      return;
    unsubscribe(_subscribedService, _subscriptionKind);
    _subscribedService = null;
    _subscriptionKind = "";
  }
}
