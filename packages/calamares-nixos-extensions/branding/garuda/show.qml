import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Image {
        anchors.centerIn: parent
        width: 240; height: 240
        source: "images/garuda.webp"
        fillMode: Image.PreserveAspectFit
        opacity: 0.9
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        color: "#CBA6F7"
        font.pixelSize: 28
        text: "Garuda Linux — The Nix Side"
    }

    function onActivate() {
    }

    function onLeave() {
    }
}