import QtQuick 2.15
import QtQuick.Controls 2.15
import SddmComponents 2.0

Rectangle {
    readonly property var fontFamily: "JetBrains Mono";
    readonly property var bootupText: "EXELSIOR:ARCH";
    readonly property var primary: '#fff';

    id: root;
    anchors.fill: parent;
    color: "#000"; // Pitch black again

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Delete &&
            (event.modifiers & Qt.ControlModifier) &&
            (event.modifiers & Qt.AltModifier)) {

            sddm.reboot()
            event.accepted = true
        }
    }

    Rectangle {
        id: viewport;
        // anchors.fill: parent;
        anchors.centerIn: parent;
        color: "#000"; // Pitch fucking black
        // clip: true; // Clip the effects when it goes out of bounds

        // W/H as the aspect ratio
        width: (parent.width / parent.height > 16/9) 
                ? (parent.height * 16/9) 
                : parent.width
                
        height: (parent.width / parent.height > 16/9) 
                ? parent.height 
                : (parent.width * 9/16)

        // STARTING ANIMATIONS
        // Starting animation: Big Textbox
        Rectangle {
            id: start_bigtextbox
            width: 0;
            height: 80;
            y: (viewport.height - height) / 2; // Fucking maths
            anchors.horizontalCenter: parent.horizontalCenter;
            color: "#000";  

            property int charCount: 0;

            // Starting animation: Big Textbox's Text
            Text {
                id: start_bigtextbox_text
                anchors.left: start_bigtextbox.left;
                anchors.leftMargin: 30;

                // height: 80;
                anchors.verticalCenter: start_bigtextbox.verticalCenter;

                color: "#fff";

                text: bootupText.substr(0, start_bigtextbox.charCount) + "_";
                font.family: fontFamily;
                font.bold: true;
                font.pointSize: 25;
            }

            Rectangle {
                id: start_bigtextbox_cover
                height: start_bigtextbox.height;
                anchors.left: start_bigtextbox.left;

                color: primary;
                // border.width: 1;
                // border.color: "#fff";

                width: 0;
                clip: true;

                Text {
                    id: start_bigtextbox_cover_text
                    anchors.left: start_bigtextbox_cover.left;
                    anchors.leftMargin:30;

                    anchors.verticalCenter: start_bigtextbox_cover.verticalCenter;

                    color: "#000";

                    text: "> KRISTA";
                    font.family: fontFamily;
                    font.bold: true;
                    font.pointSize: 25;
                }

                Text {
                    id: start_bigtextbox_cover_text2
                    anchors.right: start_bigtextbox_cover.right;
                    anchors.rightMargin:30;

                    anchors.verticalCenter: start_bigtextbox_cover.verticalCenter;

                    color: '#000';

                    text: "OK";
                    font.family: fontFamily;
                    font.bold: true;
                    font.pointSize: 25;

                    opacity: 0;
                }
            }

            Text {
                id: start_bigtextbox_undertext1
                anchors.top: start_bigtextbox.bottom;
                anchors.topMargin: 30;
                anchors.left: start_bigtextbox.left;
                anchors.leftMargin: 20;

                color: primary;

                property var logtext: "HEALTH: ";
                property int ltcount: 0;

                text: logtext.substr(0, ltcount);
                font.family: fontFamily;
                font.bold: true;
                font.pointSize: 10;
            }

            Text {
                id: start_bigtextbox_undertext2
                anchors.top: start_bigtextbox.bottom;
                anchors.topMargin: 30;
                anchors.right: start_bigtextbox.right;
                anchors.rightMargin: 20;

                color: primary;

                property var logtext: "OK";
                property int ltcount: 0;

                text: logtext.substr(0, ltcount);
                font.family: fontFamily;
                font.bold: true;
                font.pointSize: 10;
            }

            Text {
                id: start_bigtextbox_undertext3
                anchors.top: start_bigtextbox.bottom;
                anchors.topMargin: 50;
                anchors.left: start_bigtextbox.left;
                anchors.leftMargin: 20;

                color: primary;

                property var logtext: "SYSTEM SCAN: ";
                property int ltcount: 0;

                text: logtext.substr(0, ltcount);
                font.family: fontFamily;
                font.bold: true;
                font.pointSize: 10;
            }

            Text {
                id: start_bigtextbox_undertext4
                anchors.top: start_bigtextbox.bottom;
                anchors.topMargin: 50;
                anchors.right: start_bigtextbox.right;
                anchors.rightMargin: 20;

                color: primary;

                property var logtext: "WARN";
                property int ltcount: 0;

                text: logtext.substr(0, ltcount);
                font.family: fontFamily;
                font.bold: true;
                font.pointSize: 10;
            }

            Text {
                id: start_bigtextbox_undertext5
                anchors.top: start_bigtextbox.bottom;
                anchors.topMargin: 70;
                anchors.left: start_bigtextbox.left;
                anchors.leftMargin: 20;

                color: primary;

                property var logtext: "USER STATUS: ";
                property int ltcount: 0;

                text: logtext.substr(0, ltcount);
                font.family: fontFamily;
                font.bold: true;
                font.pointSize: 10;
            }

            Text {
                id: start_bigtextbox_undertext6
                anchors.top: start_bigtextbox.bottom;
                anchors.topMargin: 70;
                anchors.right: start_bigtextbox.right;
                anchors.rightMargin: 20;

                color: primary;

                property var logtext: "ALIVE";
                property int ltcount: 0;

                text: logtext.substr(0, ltcount);
                font.family: fontFamily;
                font.bold: true;
                font.pointSize: 10;
            }
        }

        // SESSION SELECT
        SpinBox {
            id: session_selector
            width: 130
            height: 40

            opacity: 0;

            from: 0
            to: Math.max(0, sessionModel.count - 1)
            value: 0; 

            anchors.right: viewport.right;
            anchors.rightMargin: 50;
            anchors.bottom: viewport.bottom;
            anchors.bottomMargin: 50;

            background: Rectangle {
                color: "#000"
                // border.color: "#fff"
                // border.width: 1
            }

            contentItem: TextInput {
                leftPadding: 10
                rightPadding: 10
                text: session_selector.value
                color: "#fff"
                
                font.family: fontFamily
                font.pointSize: 10
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                readOnly: true
                validator: session_selector.validator
            }

            up.indicator: Rectangle {
                x: session_selector.width - width
                width: 40
                height: session_selector.height
                color: session_selector.up.pressed ? "#fff" : "#000"
                // border.color: "#fff"
                // border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: ">"
                    color: session_selector.up.pressed ? "#000" : "#fff"
                    font.family: fontFamily
                    font.pointSize: 14
                }
            }

            down.indicator: Rectangle {
                width: 40
                height: session_selector.height
                color: session_selector.down.pressed ? "#fff" : "#000"
                // border.color: "#fff"
                // border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "<"
                    color: session_selector.down.pressed ? "#000" : "#fff"
                    font.family: fontFamily
                    font.pointSize: 14
                }
            }
        }

        // USER COMPONENTS
        // User image
        Rectangle {
            id: user_image_container;

            width: 500;
            height: 0;

            color: primary;

            y: (viewport.height - width) / 2;
            x: (viewport.width / 2) - width - 40;

            Image {
                id: user_image;
                anchors.centerIn: parent;

                antialiasing: true;

                width: parent.width - 10; // Border of 1
                height: parent.height - 10;

		source: "file:///usr/share/sddm/themes/eclraria/Image.jpg";
                fillMode: Image.PreserveAspectCrop;
                visible: source != ""; // As long as the source exists.
		}
		
	    Text {
                id: user_image_undertext1
                anchors.top: user_image.bottom;
                anchors.topMargin: 30;
                anchors.left: user_image.left;
                anchors.leftMargin: 20;

                color: primary;

                property var logtext: "Pinging HOST.............OK\n[IRIS] Responses System ENABLED\n[IRIS] System checks completed.\n[SYST] Found '1' candidate.\nTransferring data.....OK\n\nWELCOME BACK, USER.";
                property int ltcount: 0;

                text: logtext.substr(0, ltcount);
                font.family: fontFamily;
                font.bold: true;
		font.pointSize: 10;

		lineHeight: 1;
            }
        }

        TextField {
            id: username_field

            clip: true;

            width: 0;
            height: 50;
            // background: Rectangle { implicitWidth: 540; height: 70; color: "#000"; border.width: 1; border.color: "#fff"; anchors.centerIn: parent; }
            background: Rectangle { color: "#000" }

            y: (viewport.height / 2) - 80;
            x: (viewport.width / 2) + 40;

            color: "#fff";
            // textColor: "#fff";
            placeholderText: "Username";
            font.family: fontFamily;
            font.bold: true;
            font.pointSize: 20;
        }

        TextField {
            id: passwd_field

            clip: true;

            width: 0;
            height: 50;
            // background: Rectangle { implicitWidth: 540; height: 70; color: "#000"; border.width: 1; border.color: "#fff"; anchors.centerIn: parent; }
            background: Rectangle { color: "#000" }
            echoMode: TextInput.Password

            y: (viewport.height / 2) + 40;
            x: (viewport.width / 2) + 40;

            color: "#fff";
            // textColor: "#fff";
            placeholderText: "Password";
            font.family: fontFamily;
            font.bold: true;
            font.pointSize: 20;
            // font.letterSpacing: 3;
            passwordCharacter: '*'
		
	    Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
	            // Trigger your login function here
            	    sddm.login(username_field.text, passwd_field.text, session_selector.value);
		    event.accepted = true;
		}
            }
        }

        // Animations
        SequentialAnimation {
            id: seq_anim;
            // Computer NAME REVEAL
            PauseAnimation { duration: 1200; }

            NumberAnimation {
                id: start_anim_1a;
                target: start_bigtextbox;
                property: "width";

                from: 0;
                to: 500;
                duration: 600;
                
                easing.type: Easing.OutCubic;
            }

            NumberAnimation {
                id: start_anim_1b;
                target: start_bigtextbox;
                property: "charCount";
                
                from: 0;
                to: bootupText.length;

                duration: 700;
                // easing.type: Easing.OutCubic;
            }

            NumberAnimation {
                id: start_anim_1c;
                target: start_bigtextbox_cover;
                property: "width";

                from: 0;
                to: 500;
                duration: 600;
                
                easing.type: Easing.OutCubic;
            }

            PauseAnimation { duration: 100; }

            NumberAnimation {
                id: start_anim_1d
                target: start_bigtextbox_cover_text2;
                property: "opacity";

                from: 0;
                to: 1;

                duration: 100;
            }

            // MOVE THE NAME UP AND SHOW THE GODDAMN LOGIN PANELS
            NumberAnimation {
                id: start_anim_2a
                target: start_bigtextbox;
                property: "y";

                to: 40;

                duration: 300;
                easing.type: Easing.OutCubic;
            }

            NumberAnimation { id: start_anim_2b1; target: start_bigtextbox_undertext1; property: "ltcount"; from: 0; to: start_bigtextbox_undertext1.logtext.length; duration: 200; easing.type: Easing.OutQuad; }
            NumberAnimation { id: start_anim_2b2; target: start_bigtextbox_undertext2; property: "ltcount"; from: 0; to: start_bigtextbox_undertext2.logtext.length; duration: 200; easing.type: Easing.OutQuad; }
            NumberAnimation { id: start_anim_2b3; target: start_bigtextbox_undertext3; property: "ltcount"; from: 0; to: start_bigtextbox_undertext3.logtext.length; duration: 200; easing.type: Easing.OutQuad; }
            NumberAnimation { id: start_anim_2b4; target: start_bigtextbox_undertext4; property: "ltcount"; from: 0; to: start_bigtextbox_undertext4.logtext.length; duration: 200; easing.type: Easing.OutQuad; }
            NumberAnimation { id: start_anim_2b5; target: start_bigtextbox_undertext5; property: "ltcount"; from: 0; to: start_bigtextbox_undertext5.logtext.length; duration: 200; easing.type: Easing.OutQuad; }
            NumberAnimation { id: start_anim_2b6; target: start_bigtextbox_undertext6; property: "ltcount"; from: 0; to: start_bigtextbox_undertext6.logtext.length; duration: 200; easing.type: Easing.OutQuad; }

            // USER IMAGE GROW
            NumberAnimation {
                id: start_anim_2c
                target: user_image_container
                property: "height"
                // from: 0
                to: 500;
                // Explicitly use viewport.height to avoid logic loops
                duration: 500
                easing.type: Easing.OutCubic
            }

	    // FIELDS
	    ScriptAction {
		    script: username_field.text = userModel.lastUser;
            }

            NumberAnimation {
                id: start_anim_2d1
                target: username_field;
                property: "width";

                to: 500;

                duration: 500;
                easing.type: Easing.OutCubic;
	    } 

            NumberAnimation {
                id: start_anim_2d2
                target: passwd_field;
                property: "width";

                to: 500;

                duration: 500;
                easing.type: Easing.OutCubic;
            }
            
	    ScriptAction {
		    script: passwd_field.forceActiveFocus();
	    }

            NumberAnimation {
                id: start_anim_3a
                target: session_selector;
                property: "opacity";

                to: 1;

                duration: 400;
            }

            NumberAnimation { id: start_anim_3b1; target: user_image_undertext1; property: "ltcount"; from: 0; to: user_image_undertext1.logtext.length; duration: 3000; easing.type: Easing.OutCubic; }
        }

	Component.onCompleted: { 
	    // username_field.text = userModel.lastUser;
	    seq_anim.start();
            session_selector.value = sessionModel.lastIndex;
        }
    }

}
