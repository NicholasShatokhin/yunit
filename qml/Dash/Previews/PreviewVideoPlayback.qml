/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import "../../Components"

/*! \brief Preview widget for video.

    This widget shows video contained in widgetData["source"],
    with a placeholder screenshow specified by widgetData["screenshot"].
 */

PreviewWidget {
    id: root
    implicitHeight: units.gu(22)

    LazyImage {
        objectName: "screenshot"
        anchors.left: parent.left
        anchors.right: parent.right
        scaleTo: "width"
        visible: height > 0
        source: widgetData["screenshot"]
        initialHeight: width * 10 / 16

        Image {
            objectName: "playButton"

            readonly property bool bigButton: parent.width > units.gu(40)

            anchors.centerIn: parent
            width: bigButton ? units.gu(8) : units.gu(4.5)
            height: width
            source: "../graphics/play_button%1%2.png".arg(previewImageMouseArea.pressed ? "_active" : "").arg(bigButton ? "_big" : "")
        }

        MouseArea {
            id: previewImageMouseArea
            anchors.fill: parent
            onClicked: {
                //Qt.openUrlExternally(widgetData["source");
            }
        }
    }
}
