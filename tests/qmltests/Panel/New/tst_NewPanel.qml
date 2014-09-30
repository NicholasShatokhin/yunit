/*
 * Copyright 2013 Canonical Ltd.
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

import QtQuick 2.1
import QtQuick.Layouts 1.1
import QtTest 1.0
import Unity.Test 0.1 as UT
import Ubuntu.Components 0.1
import Unity.Indicators 0.1 as Indicators
import Ubuntu.Telephony 0.1 as Telephony
import "../../../../qml/Panel"

IndicatorTest {
    id: root
    width: units.gu(100)
    height: units.gu(71)
    color: "white"

    property string indicatorProfile: "phone"

    RowLayout {
        anchors.fill: parent
        anchors.margins: units.gu(1)
        clip: true

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            id: itemArea
            color: "blue"

            Panel {
                id: panel
                anchors.fill: parent
                indicators {
                    width: parent.width > units.gu(60) ? units.gu(40) : parent.width
                    indicatorsModel: root.indicatorsModel
                }

                property real panelAndSeparatorHeight: panel.indicators.minimizedPanelHeight + units.dp(2)
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: false

            Button {
                Layout.fillWidth: true
                text: panel.indicators.shown ? "Hide" : "Show"
                onClicked: {
                    if (panel.indicators.shown) {
                        panel.indicators.hide();
                    } else {
                        panel.indicators.show();
                    }
                }
            }

            Button {
                text: panel.fullscreenMode ? "Maximize" : "FullScreen"
                Layout.fillWidth: true
                onClicked: panel.fullscreenMode = !panel.fullscreenMode
            }

            Button {
                Layout.fillWidth: true
                text: callManager.hasCalls ? "Called" : "No Calls"
                onClicked: {
                    if (callManager.foregroundCall) {
                        callManager.foregroundCall = null;
                    } else {
                        callManager.foregroundCall = phoneCall;
                    }
                }
            }

            Rectangle {
                Layout.preferredHeight: units.dp(1);
                Layout.fillWidth: true;
                color: "black"
            }

            Repeater {
                model: indicatorsModel.originalModelData
                RowLayout {
                    CheckBox {
                        checked: true
                        onCheckedChanged: checked ? insertIndicator(index) : removeIndicator(index);
                    }
                    Label { text: modelData["identifier"] }
                }
            }
        }
    }

    Telephony.CallEntry {
        id: phoneCall
        phoneNumber: "+447812221111"
    }

    UT.UnityTestCase {
        name: "Panel"
        when: windowShown

        function init() {
            panel.fullscreenMode = false;
            callManager.foregroundCall = null;

            panel.indicators.hide();
            // Wait for animation to complete
            tryCompare(panel.indicators.hideAnimation, "running", false);

            // Wait for the indicators to get into position.
            // (switches between normal and fullscreen modes are animated)
            var indicatorArea = findChild(panel, "indicatorArea");
            tryCompare(indicatorArea, "y", 0);
        }

        function get_indicator_item(index) {
            var indicatorItem = findChild(panel, indicatorsModel.originalModelData[index]["identifier"]+"-panelItem");
            verify(indicatorItem !== null);

            return indicatorItem;
        }

        function test_drag_show_data() {
            return [
                { tag: "pinned", fullscreen: false, call: null,
                            indicatorY: 0 },
                { tag: "fullscreen", fullscreen: true, call: null,
                            indicatorY: -panel.panelAndSeparatorHeight },
                { tag: "pinned-callActive", fullscreen: false, call: phoneCall,
                            indicatorY: 0},
                { tag: "fullscreen-callActive", fullscreen: true, call: phoneCall,
                            indicatorY: -panel.panelAndSeparatorHeight }
            ];
        }

        // Dragging from a indicator item in the panel will gradually expose the
        // indicators, first by running the hint animation, then after dragging down will
        // expose more of the panel, binding it to the selected indicator and opening it's menu.
        function test_drag_show(data) {
            panel.fullscreenMode = data.fullscreen;
            callManager.foregroundCall = data.call;

            var indicatorRow = findChild(panel.indicators, "indicatorItemRow");
            verify(indicatorRow !== null);

            var menuContent = findChild(panel.indicators, "menuContent");
            verify(menuContent !== null);

            var indicatorArea = findChild(panel, "indicatorArea");
            verify(indicatorArea !== null);

            // Wait for the indicators to get into position.
            // (switches between normal and fullscreen modes are animated)
            tryCompareFunction(function() { return indicatorArea.y }, data.indicatorY);

            for (var i = 0; i < indicatorsModel.originalModelData.length; i++) {
                var indicatorItem = get_indicator_item(i);
                var mappedPosition = root.mapFromItem(indicatorItem, indicatorItem.width / 2, indicatorItem.height / 2);

                touchFlick(panel,
                           mappedPosition.x, panel.indicators.minimizedPanelHeight / 2,
                           mappedPosition.x, panel.height,
                           true /* beginTouch */, false /* endTouch */, units.gu(5), 15);

                // Indicators height should follow the drag, and therefore increase accordingly.
                // They should be at least half-way through the screen
                tryCompareFunction(
                    function() {return panel.indicators.height >= panel.height * 0.5},
                    true);

                touchRelease(panel, mappedPosition.x, panel.height);

                compare(indicatorRow.currentItemIndex, i,  "Indicator item should be activated at position " + i);
                compare(menuContent.currentMenuIndex, i, "Menu conetent should be activated for item at position " + i);

                // init for next indicatorItem
                panel.indicators.hide();
                tryCompare(panel.indicators.hideAnimation, "running", false);
                tryCompare(panel.indicators, "state", "initial");
            }
        }

        function test_hint_data() {
            return [
                { tag: "normal", fullscreen: false, call: null, hintExpected: true},
                { tag: "fullscreen", fullscreen: true, call: null, hintExpected: false},
                { tag: "call hint", fullscreen: false, call: phoneCall, hintExpected: false},
            ];
        }

        function test_hint(data) {
            panel.fullscreenMode = data.fullscreen;
            callManager.foregroundCall = data.call;

            if (data.fullscreen) {
                // Wait for the indicators to get into position.
                // (switches between normal and fullscreen modes are animated)
                var indicatorArea = findChild(panel, "indicatorArea");
                tryCompare(indicatorArea, "y", -panel.panelHeight);
            }

            var indicatorItem = get_indicator_item(0);
            var mappedPosition = root.mapFromItem(indicatorItem, indicatorItem.width / 2, indicatorItem.height / 2);

            touchPress(panel, mappedPosition.x, panel.indicators.minimizedPanelHeight / 2);

            // Give some time for a hint animation to change things, if any
            wait(500);

            // no hint animation when fullscreen
            compare(panel.indicators.fullyClosed, !data.hintExpected, "Indicator should be fully closed");
            compare(panel.indicators.partiallyOpened, data.hintExpected, "Indicator should be partialy opened");
            compare(panel.indicators.fullyOpened, false, "Indicator should not be fully opened");

            touchRelease(panel, mappedPosition.x, panel.minimizedPanelHeight / 2);
        }
    }
}
