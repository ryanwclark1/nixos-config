import QtQuick

QtObject {
  required property QtObject service
  Component.onCompleted: service.subscriberCount++
  Component.onDestruction: service.subscriberCount--
}
