pragma Singleton

import QtQuick
import qs.Commons

QtObject {
  readonly property color background: Color.background
  readonly property color on_surface: Color.foreground
  readonly property color on_surface_variant: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.72)
  readonly property color surface_container_low: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.055)
  readonly property color surface_container: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.085)
  readonly property color surface_container_high: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.13)
  readonly property color surface_container_highest: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.18)
  readonly property color outline: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.34)
  readonly property color outline_variant: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.18)
  readonly property color primary: Color.accent
  readonly property color on_primary: Color.background
  readonly property color primary_container: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
  readonly property color on_primary_container: Color.foreground
  readonly property color tertiary: Color.accent
  readonly property color error: Color.urgent
}
