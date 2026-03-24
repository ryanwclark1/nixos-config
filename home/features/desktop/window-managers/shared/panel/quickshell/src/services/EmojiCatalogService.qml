pragma Singleton

import QtQuick
import "../launcher/CharacterData.js" as CharacterData

QtObject {
    readonly property var characterEntries: CharacterData.characterEntries
}
