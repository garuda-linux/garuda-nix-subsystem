import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation
    fontFamily: "Inter, Fira Sans"
    textColor: "#cdd6f4"

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        z: -1
    }

    Slide {
        Image {
            anchors.centerIn: parent
            width: 240; height: 240
            source: "images/garuda.svg"
            fillMode: Image.PreserveAspectFit
            opacity: 0.9
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 64
            color: "#CBA6F7"
            font.pixelSize: 28
            text: "Welcome to Garuda Nix!"
        }
    }

    Slide {
        Text {
            anchors.centerIn: parent
            color: "#CBA6F7"
            font.pixelSize: 32
            horizontalAlignment: Text.AlignHCenter
            text: "Declarative. Reproducible.\nYour system, versioned in a flake."
        }
    }

    Slide {
        Text {
            anchors.centerIn: parent
            color: "#CBA6F7"
            font.pixelSize: 32
            horizontalAlignment: Text.AlignHCenter
            text: "Check out further options at the documentation\nat nix.garudalinux.org."
        }
    }

    Slide {
        Text {
            anchors.centerIn: parent
            color: "#CBA6F7"
            font.pixelSize: 32
            horizontalAlignment: Text.AlignHCenter
            text: "Sit back while your system\nis being installed!"
        }
    }

    function onActivate() {
    }

    function onLeave() {
    }
}
