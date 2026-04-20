import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

ShellRoot {
	id: root;

	readonly property var defaultFont: "JetBrains Mono"
	readonly property var fontSize: 11;

	// Stats
	property var cpuUsage: "0%";         // mpstat 1 1 | awk 'END{print 100-$NF "%"}'
	property var ramUsage: "0%";         // free | grep Mem | awk '{print $3/$2 * 100.0 "%"}'
	property var diskUsage: "0%";        // df / --output=pcent | tail -1'
	property var netUpUsage: "0 KB/s";   // Upload
	property var netDownUsage: "0 KB/s"; // Download
	property var batteryLevel: "0%"; // acpi -b | awk '{print $4}' | tr -d ','
	property bool charging: false;

	// Pipewire
	PwObjectTracker {
		id: pwTracker
		objects: [Pipewire.defaultAudioSink]
	}

	readonly property PwNode sink: Pipewire.defaultAudioSink;

	// Volume Popup
	// Visibility state
	property bool volVisible: false;
	property real vol: (sink.audio.muted ? sink.audio.volume - 100 : sink.audio.volume);
	onVolChanged: {
		volVisible = true
		hideTimer.restart()
	}

	// Auto-hide timer — resets on each volume change
	Timer {
		id: hideTimer;
		interval: 1000;  // hide after 1 seconds of no changes
		running: true;
		onTriggered: volVisible = false
	}

	// Stats updater
	Process {
		id: battery_mon
		running: true;
		onRunningChanged: if (!running) running = true;

		command: ["sh", "-c", "
		acpi - b;
		sleep 1;
		"]
		
		stdout: SplitParser {
			onRead: data => {
				var out = data.split(", ");
				if (out[0].includes("Discharging")) charging = false;
				else charging = true;

				batteryLevel = out[1];	
			}
		}
	}

	Process {
		id: cpu_mon
		running: true;
		onRunningChanged: if (!running) running = true;

		command: ["sh", "-c", "
		mpstat 1 1 | awk 'END{print 100-$NF}';
		sleep 1;
		"]
		
		stdout: SplitParser {
			onRead: data => cpuUsage = Math.round(parseFloat(data)) + "%";
		}
	}

	Process {
		id: ram_mon
		running: true;
		onRunningChanged: if (!running) running = true;

		command: ["sh", "-c", "
		free | grep Mem | awk '{print $3/$2 * 100.0}'
		sleep 3;
		"]

		stdout: SplitParser {
			onRead: data => ramUsage = Math.round(parseFloat(data)) + "%";
		}
	}

	Process {
		id: disk_mon
		running: true;
		onRunningChanged: if (!running) running = true;

		command: ["sh", "-c", "
		df / --output=pcent | tail -1;
		sleep 10;
		"]

		stdout: SplitParser {
			onRead: data => diskUsage = data;
		}
	}

	Process {
		id: net_mon
		running: true;
		onRunningChanged: if (!running) running = true;

		command: ["sh", "-c", "
		# 1. Get the active interface
		IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

		# 2. Get initial RX (Download) and TX (Upload) bytes
		RX1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
		TX1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

		# 3. Wait exactly one second
		sleep 1

		# 4. Get the new byte counts
		RX2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
		TX2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

		# 5. Calculate the difference and convert to KB (Divide by 1024)
		RX_SPEED=$(($RX2 - $RX1))
		TX_SPEED=$(($TX2 - $TX1))

		echo \"$RX_SPEED|$TX_SPEED\"
		"]

		stdout: SplitParser {
			onRead: data => {
				function formatBytes(bytes, decimals = 2) {
					if (bytes === 0) return '0 Bytes';

					const k = 1024;
					const dm = decimals < 0 ? 0 : decimals;
					const sizes = ['B', 'KB', 'MB', 'GB'];

					// This calculates which index of the 'sizes' array to use
					const i = Math.floor(Math.log(bytes) / Math.log(k));

					// Ensure we don't exceed the 'GB' index in the array
					const index = Math.min(i, sizes.length - 1);

					if (index < 0) return "0 B";

					return parseFloat((bytes / Math.pow(k, index)).toFixed(dm)) + ' ' + sizes[index];
				}

				let out = data.split("|");
				
				// RX: Recieve - Download
				netDownUsage = formatBytes(out[0]) + "/s";

				// TX: Transmit - Upload
				netUpUsage = formatBytes(out[1]) + "/s";
			}
		}
	}

	PanelWindow {
		id: panel;

		anchors { top: true; left: true; right: true; }
		height: 40; // Quite tall but still isn't that tall
		margins { top: 15; left: 15; right: 15; bottom: 0; } // The margins? suck ass
		color: "#00000000";
		
		// SYSTEM CLOCK
		SystemClock {
			id: clock;
			precision: SystemClock.Seconds;
		}
		
		Row {
			// anchors.right: parent.right;
			// anchors.left: parent.left;
			anchors.fill: parent;

			spacing: 10;

			// FRAME: SYSTEM CLOCK
			Rectangle {
				id: clock_bg;
				// anchors.centerIn: panel;
				width: 250;
				height: 40;
				color: "#fff"; // Pitch black background
				border.width: 1;
				border.color: "#fff";

				anchors.centerIn: parent;

				Label {
					id: clock_label
					text: Qt.formatDateTime(
						clock.date,
						"hh:mm:ss // dd-MM-yyyy"
					);
					font.family: defaultFont;
					font.pointSize: 11;
					font.weight: 700;
					color: "#000";

					// Alignments
					anchors.centerIn: clock_bg;
				}
			}

			// FRAME: MEDIA PLAYER	
			Rectangle {
				visible: Mpris.players.values.length > 0;

				anchors.right: clock_bg.left;
				anchors.rightMargin: 10;
				anchors.verticalCenter: clock_bg.verticalCenter;

				id: media_bg
				width: 200;
				height: 40;
				color: "#000b1a";
				border.width: 1;
				border.color: Mpris.players.values[0]?.trackArtUrl ? "#aaa" : "#aaa";
				
				// readonly property var currentPlayer: Mpris.;
				// DYNAMIC BACKGROUND IMAGE: IMAGE
				Image {
					id: media_dynamic_bg
					anchors.fill: parent;
					anchors.margins: parent.border.width;

					source: Mpris.players.values[0]?.trackArtUrl ?? "";
					fillMode: Image.PreserveAspectCrop;
					visible: source != ""; // As long as the source exists.

					asynchronous: true;
				}

				// DYNAMIC BACKGROUND IMAGE: BLUR EFFECT
				MultiEffect {
					anchors.fill: media_dynamic_bg;
					source: media_dynamic_bg;
					
					autoPaddingEnabled: false;

					brightness: -0.5;
					saturation: 0.4;
					blurEnabled: true;
					blurMax: 64;
					blur: 1.0;
				}

				// TRACK INFO
				Column {
					anchors.centerIn: parent;
					// spacing: 10;
					// margins: { left: 10; }

					Text {
						text: Mpris.players.values[0]?.trackTitle ?? "Unknown Title";
						// anchors.horizontalCenter: parent.horizontalCenter;
						horizontalAlignment: Text.AlignHCenter;
	
						color: "#fff";

						font.family: defaultFont;
						font.pointSize: 9;
						
						// Add the '...'
						width: 180;
						elide: Text.ElideRight;
					}

					Text {
						text: Mpris.players.values[0]?.trackArtist ?? "Unknown Artist";
						// anchors.horizontalCenter: parent.horizontalCenter;
						horizontalAlignment: Text.AlignHCenter;

						color: "#77ffffff";

						font.family: defaultFont;
						font.pointSize: 7;

						width: 180;
						elide: Text.ElideRight;
					}
				}
			}	

			// FRAME: FOCUSED WINDOW
			Rectangle {
				visible: ToplevelManager.toplevels.values.length > 0;

				id: focused_bg;

				width: 200;
				height: 40;

				anchors.left: clock_bg.right;
				anchors.leftMargin: 10;
				anchors.verticalCenter: clock_bg.verticalCenter;

				color: "#aa000000";

				border.width: 1;
				border.color: "#aaa";

				// Image {
				// 	id: mainBackground
				// 	anchors.fill: parent
				// 	source: "your-image.jpg"
				// 	fillMode: Image.PreserveAspectCrop
				// }

				Label {
					id: focused_label;

					width: 180;
					anchors.centerIn: parent;
					horizontalAlignment: Text.AlignHCenter;
					verticalAlignment: Text.AlignVCenter;

					font.family: defaultFont;
					font.pointSize: 10;

					font.weight: 500;
					font.italic: true;
					color: "#aaa";

					text: ToplevelManager.activeToplevel.title;

					elide: Text.ElideRight;
				}
			}
		}

		Row {
			anchors.left: parent.left;
			Rectangle {
				id: battery_display;
				anchors.left: parent.left;

				color: "#000";
				border.width: 1;
				border.color: "#fff";

				width: 80;
				height: 40;

				Label {
					id: battery_label;

					anchors.centerIn: parent;

					color: (charging ? "#52ff63" : "#fff");
					font.family: defaultFont;
					font.pointSize: 10;
					font.bold: true;

					text: (charging ? " " : "󰁹 ") + batteryLevel;
				}
			}


			Row {
				id: workspacesRow;
				spacing: 10;
	
				anchors.left: battery_display.right;
				anchors.leftMargin: 10;
	
				// Handles the very first time the bar loads
				populate: Transition {
					NumberAnimation { 
						properties: "scale,opacity"; 
						from: 0; 
						duration: 200; 
						easing.type: Easing.OutBack 
					}
				}
	
				// Handles new workspaces being created
				add: Transition {
					NumberAnimation { 
						properties: "scale,opacity"; 
						from: 0; 
						duration: 200; 
						easing.type: Easing.OutBack 
					}
				}
	
				// CRITICAL: Handles existing workspaces sliding when others are removed
				move: Transition {
					NumberAnimation { 
						properties: "x,y"; 
						duration: 200; 
						easing.type: Easing.OutCubic 
					}
				}

				Repeater {
					// Use the workspaces model from the Hyprland singleton
					model: Hyprland.workspaces

					delegate: Rectangle {
						id: rect
						required property var modelData
						property bool isChosen: Hyprland.focusedWorkspace === modelData
	
						width: 30; height: 40
	
						// Set initial state for the 'add' transition to pick up
						opacity: 1
						scale: 1
	
						border.width: 1
						border.color: isChosen ? "#fff" : "#999999"
	
						color: (isChosen) ? "#fff" : (workspaces_hover_handler.hovered ? "#333" : "#000");
	
						// Behavior handles the selection toggle animation
						Behavior on color { ColorAnimation { duration: 150 } }
						Behavior on border.color { ColorAnimation { duration: 150 } }
	
						Text {
							font.family: defaultFont;
							font.pointSize: 10
							font.weight: 500
							anchors.centerIn: parent
							text: modelData.name === "10" ? "0" : modelData.name
							color: isChosen ? "#000" : "#fff";
							Behavior on color { ColorAnimation { duration: 150 } }
						}
	
						HoverHandler {
							id: workspaces_hover_handler;
							// anchors.fill: parent;
						}
	
						MouseArea {
							anchors.fill: parent
							onClicked: modelData.activate()
						}
					}
				}
			}
		}

		Row {
			id: stats_row;

			spacing: 10;
			anchors.right: parent.right; // Align right.

			Rectangle {
				id: net_display

				color: "#000";
				border.width: 1;
				border.color: "#ff8e47ff";

				width: childrenRect.width + 40;
				height: 40;
				
				Behavior on width {
					NumberAnimation {
						duration: 300;
						easing.type: Easing.OutCubic;
					}
				}

				Label {
					id: net_label;

					anchors.centerIn: parent;

					color: "#ff8e47ff";
					font.family: defaultFont;
					font.pointSize: 10;
					font.bold: true;

					text: "󰁝 " + netUpUsage + "  󰁅 " + netDownUsage;
				}
			}
			
			Rectangle {
				id: cpu_usage_display

				color: "#000";
				border.width: 1;
				border.color: "#ff4794ff";

				width: 80;
				height: 40;

				Label {
					id: cpu_usage_label;

					anchors.centerIn: parent;

					color: "#ff4794ff";
					font.family: defaultFont;
					font.pointSize: 10;
					font.bold: true;

					text: " " + cpuUsage;
				}
			}

			Rectangle {
				id: ram_usage_display

				color: "#000";
				border.width: 1;
				border.color: "#ffffdd47";

				width: 80;
				height: 40;

				Label {
					id: ram_usage_label;

					anchors.centerIn: parent;

					color: "#ffffdd47";
					font.family: defaultFont;
					font.pointSize: 10;
					font.bold: true;

					text: "󰍜 " + ramUsage;
				}
			}

			Rectangle {
				id: disk_display

				color: "#000";
				border.width: 1;
				border.color: "#ff47ff60";

				width: 80;
				height: 40;

				Label {
					id: disk_label;

					anchors.centerIn: parent;

					color: "#ff47ff60";
					font.family: defaultFont;
					font.pointSize: 10;
					font.bold: true;

					text: " " + diskUsage;
				}
			}	
		}

		// VOLUME AND BRIGHTNESS

		// VOLUME
		PopupWindow {
			property int yValue: volVisible ? (parentWindow.height + 50) : (parentWindow.height + 0);

			id: volume_popup;
			anchor.window: panel;
			anchor.rect.y: yValue; // Padding of 50 from the bottom edge
			anchor.rect.x: (parentWindow.width - width) / 2;
			width: 230;
			height: 40;
			visible: true;
			color: "transparent"; // transparent fucking background

			Behavior on yValue {
				NumberAnimation {
					duration: 300;
					easing.type: Easing.OutCubic;
				}
			}

			Rectangle {
				id: volume_popup_rect
				anchors.centerIn: parent
				color: "#dd000000"
				border.width: 1
				border.color: "#aaa";
				
				// clip: true;

				// width: 230;
				height: 40;

				// Animate the whole popup
				opacity: volVisible ? 1.0 : 0
				Behavior on opacity {
					NumberAnimation {
						duration: 300
						easing.type: Easing.OutCubic
					}
				}

				// Slide up on enter, slide down on exit
				width: volVisible ? 230 : 110
				Behavior on width {
					NumberAnimation {
						duration: 300
						easing.type: Easing.OutCubic
					}
				}

				Text {
					id: indicator
					font.family: defaultFont
					font.pointSize: (volVisible ? 15 : 1);
					font.bold: true
					height: parent.height
					anchors.left: parent.left
					anchors.leftMargin: 20
					verticalAlignment: Text.AlignVCenter
					color: "#fff"
					text: (sink.audio.muted ? "󰝟" : "󰕾");

					width: 18;

					Behavior on font.pointSize {
						NumberAnimation {
							duration: 300;
							easing.type: Easing.OutQuad;
						}
					}
				}

				Rectangle {
					id: volume_popup_displaybg
					color: '#1b1b1b'
					anchors.left: indicator.right
					anchors.leftMargin: 15
					anchors.right: parent.right
					anchors.rightMargin: 20
					anchors.verticalCenter: parent.verticalCenter
					height: 8

					Rectangle {
						id: volume_popup_display
						color: "#fff"
						anchors.left: parent.left
						anchors.top: parent.top
						anchors.bottom: parent.bottom
						width: (volVisible ? (sink?.audio?.volume ?? 0) * parent.width : 0)

						Behavior on width {
							NumberAnimation { 
								duration: 150;
								easing.type: Easing.OutCubic;
							}
						}
					}
				}
			}
		}
	}
}
