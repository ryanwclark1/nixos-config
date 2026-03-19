import QtQuick

QtObject {
  required property QtObject service
  property bool active: true
  property bool _subscribed: false
  readonly property bool _supportsSubscriptionCount: service && service.subscriberCount !== undefined

  function syncSubscription() {
    if (!service || !_supportsSubscriptionCount)
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
    if (!_subscribed || !service || !_supportsSubscriptionCount)
      return;
    service.subscriberCount--;
    _subscribed = false;
  }
}
