import QtQuick

QtObject {
  required property QtObject service
  property bool active: true
  property bool _subscribed: false

  function syncSubscription() {
    if (!service)
      return;
    if (active && !_subscribed) {
      service.subscriberCount++;
      _subscribed = true;
    } else if (!active && _subscribed) {
      service.subscriberCount--;
      _subscribed = false;
    }
  }

  onServiceChanged: syncSubscription()
  onActiveChanged: syncSubscription()
  Component.onCompleted: syncSubscription()
  Component.onDestruction: {
    if (!_subscribed || !service)
      return;
    service.subscriberCount--;
    _subscribed = false;
  }
}
