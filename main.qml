/* Copyright (C) 2017 reHackable

 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.

 * Author       : Patrick Pedersen <ctx.xda@gmail.com>
 *                Part of the reHackable organization <https://github.com/reHackable>

 * Description  : A primitive touch based calculator written for the reMarkable tablet
 *                The design and functionality are primarily based on the stock Android
 *                Material design calculator found on most Android 5.0+ devices

 * Notations    : Functionality for more complex maths, such as calculations with parentheses
 *                as well as common functions such as cos(), sin() etc. are planned to be
 *                implemented in the nearby future.

 */

import QtQuick 2.6
import QtQuick.Window 2.2

Window {
    id: win
    visible: true
    visibility: "FullScreen"

    height: Screen.height
    width: Screen.width

    /* Virtual Display */
    Rectangle {
        id: display

        height: 0.3645 * parent.height
        width: parent.width

        color: "white"

        /* Error Flag */
        property bool _error: false

        /** OO Abstract Display Interface **/

        function clear() {
            display_text.focus = false
            display_text.text = ""
        }

        function draw(buff) {
            display_text.text = buff
        }

        function add(ch) {
            if (_error) {
                draw(ch)
                _error = false
            } else {
                display_text.text += ch
                display_text.scale()
            }
        }

        function deleteAtCursor() {
            if (_error) {
                if (display_text.cursorPosition == 0) {
                    display_text.focus = false;
                }
                clear()
                _error = false
            } else {
                if (display_text.cursorPosition - 1 < 1) {
                    display_text.focus = false;
                }
                display_text.remove(display_text.cursorPosition - 1, display_text.cursorPosition)
                display_text.scale()
            }
        }

        function deleteLastChar() {
            if (_error) {
                clear()
                _error = false
            } else {
                display_text.text = display_text.text.substring(0, display_text.text.length - 1)
                display_text.scale()
            }
        }

        function replaceLastChar(ch) {
            display_text.text = display_text.text.substring(0, display_text.text.length - 1) + ch
            display_text.scale()
        }

        function error(msg) {
            _error = true
            display_text.text = msg
        }

        function getChar(pos) {
            return display_text.text.substring(pos, pos + 1)
        }

        function getFirstChar() {
            return getChar(0)
        }

        function getLastChar() {
            return getChar(display_text.text.length - 1);
        }

        function getBuffer() {
            return display_text.text
        }

        function getBufferLen() {
            return display_text.text.length
        }

        function isEmpty() {
            return display_text.text.length == 0 // Alternatively we could test the string aswell
        }

        TextInput {
            id: display_text
            text: qsTr("")

            anchors.verticalCenter: parent.verticalCenter

            font.pointSize: 0.00004 * (win.height * win.width)

            /* Scale text to fit into virtual display */
            function scale() {
                while(true) {
                    if (font.pointSize > 0.00001 * (win.height * win.width) && width > display.width) {
                        font.pointSize /= 2
                    }
                    else if (font.pointSize < 0.00004 * (win.height * win.width) && width * 2 <= display.width) {
                        font.pointSize *= 2
                    } else {
                        /* Ideal scale */
                        break
                    }
                }
            }
        }
    }

    /* Number Keys 0 - 9, ., = */
    Rectangle {
        id: numkeys

        height: win.height - display.height
        width: 0.733 * parent.width

        color: "black"

        anchors.top: display.bottom

        Grid {
            rows: 4
            columns: 3

            Repeater {
                id: numkeys_grid

                model: 12

                /* Number Key */
                Rectangle {
                    id: numkey

                    height: numkeys.height / 4
                    width: numkeys.width / 3

                    color: numkeys.color

                    Text {
                        id: numkey_text

                        /* Refactor this with a more mathematical or simpler solution */
                        text: {
                            var invIndex = 9 - index

                            if (invIndex > 0) {parent
                                switch(invIndex % 3) {
                                    case 0:
                                        return String(invIndex- 2)
                                    case 1:
                                        return String(invIndex + 2)
                                    default:
                                        return String(invIndex)
                                }
                            } else {
                                switch(invIndex) {
                                    case 0:
                                        return ".";
                                    case -1:
                                        return "0";
                                    case -2:
                                        return "=";
                                }
                            }
                        }

                        font.pointSize: 0.00001 * (win.height * win.width)
                        anchors.centerIn: parent
                        color: "white"
                    }

                    /* Registers clicks/touches for key */
                    MouseArea {
                        id: numkeyMouseArea
                        anchors.fill: parent

                        onClicked: {
                            /* "=" has been clicked/pressed, evaluate input */
                            if(numkey_text.text == "=")
                            {
                                if (!display.isEmpty()) {

                                    /* Adjust/Fix statement for evaluation */
                                    var stmt = display.getBuffer().split('−').join('-')
                                    stmt = stmt.split('÷').join('/')
                                    stmt = stmt.split('×').join('*')

                                    try {
                                        var res = eval(stmt)
                                        if (isFinite(res)) {

                                            /* Floor too large decimals */
                                            if (res < 0) {
                                                res = String(res).substring(0, 14) // Floor at the 14th character (12th decimal)
                                            }

                                            /* Draw result to display */
                                            display.draw(res)
                                        } else {
                                            throw ""
                                        }
                                    } catch(e) {
                                        display.error("Error")
                                    }

                                    opkeys_grid.itemAt(0).children[0].text = "CLR"
                                }
                            }

                            /* Add character to win */
                            else
                            {
                                if(opkeys_grid.itemAt(0).children[0].text === "CLR") {
                                    display.draw(numkey_text.text)
                                    opkeys_grid.itemAt(0).children[0].text = "DEL"
                                } else {
                                    display.add(numkey_text.text)
                                }
                            }
                        }
                    }

                    /* Invert Button Colors while clicked/pressed */
                    states: State {
                        name: "pressed";
                        when: numkeyMouseArea.pressed

                        PropertyChanges {
                            target: numkey;
                            color: "white"
                        }

                        PropertyChanges {
                            target: numkey_text
                            color: "black"
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: opkeys

        height: numkeys.height
        width: win.width - numkeys.width

        anchors.top: display.bottom
        anchors.left: numkeys.right

        Grid {
            rows: 5
            columns: 1

            Repeater {
                id: opkeys_grid
                model: 5

                Rectangle {
                    id: opkey

                    height: opkeys.height / 5
                    width: opkeys.width

                    Text {
                        id: opkey_text

                        anchors.centerIn: parent

                        text: operators[index]
                        font.pointSize: 0.00001 * (win.height * win.width)

                        property var operators: ["DEL", "÷", "×", "−", "+"]
                    }

                    /* Registers clicks/touches for key */
                    MouseArea {
                        id: opkeyMouseArea
                        anchors.fill: parent

                        /* Checks if last character was an operator */
                        function lastCharIsOp() {
                            for (var i = 0; i < opkey_text.operators.length; i++) {
                                if (display.getLastChar() === opkey_text.operators[i]) {
                                    return true;
                                }
                            }
                            return false;
                        }

                        /* Corrects length for following conditions to work properly with less exceptions */
                        function offset() { return (!display.isEmpty() && display.getFirstChar() === "−") }

                        onClicked: {
                            if (opkey_text.text == "DEL") {
                                if(display_text.focus) {
                                    display.deleteAtCursor()
                                } else {
                                    display.deleteLastChar()
                                }
                            }

                            else if (opkey_text.text == "CLR") {
                                display.clear()
                                opkey_text.text = "DEL"
                            }

                            else if (opkey_text.text === "−" || display.getBufferLen() - offset() && !display._error) {
                                if (lastCharIsOp() === true) {
                                    display.replaceLastChar(opkey_text.text)
                                } else {
                                    if (opkeys_grid.itemAt(0).children[0].text == "CLR") {
                                        opkeys_grid.itemAt(0).children[0].text = "DEL"
                                    }

                                    display.add(opkey_text.text)
                                }
                            }
                        }

                        onPressAndHold: {
                            /* Clear virtual display if user held DEL */
                            if (opkey_text.text == "DEL") {
                                display.clear()
                            }
                        }
                    }

                    /* Invert Button Colors while clicked/pressed */
                    states: State {
                        name: "pressed";
                        when: opkeyMouseArea.pressed

                        PropertyChanges {
                            target: opkey;
                            color: "black"
                        }

                        PropertyChanges {
                            target: opkey_text
                            color: "white"
                        }
                    }
                }
            }
        }
    }
}
