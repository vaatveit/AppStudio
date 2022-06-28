import QtQml 2.12
import QtQuick 2.12
import QtQuick.Layouts 1.3
import QtSensors 5.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

Item {
    id: control
    
    //--------------------------------------------------------------------------

    property RotationSensor rotationSensor
    property var reading: (rotationSensor && rotationSensor.reading) ? rotationSensor.reading : null

    property real levelX: reading ? Math.sin(toRadians(-reading.y)) * width / 2 : 0
    property real levelY: reading ? Math.sin(toRadians(-reading.x)) * height / 2 : 0

    property alias backgroundColor: backgroundRect.color
    property alias backgroundBorder: backgroundRect.border
    
    //--------------------------------------------------------------------------

    Behavior on levelX {
        NumberAnimation {
            duration: 100
        }
    }

    Behavior on levelY {
        NumberAnimation {
            duration: 100
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        
        color: "transparent"
        radius: height / 2
        
        border {
            color: "transparent"
            width: 3 * AppFramework.displayScaleFactor
        }
        
        visible: false
    }
    
    //    RadialGradient {
    //        source: backgroundRect

    //        anchors.fill: source
    //        gradient: Gradient {
    //            GradientStop { position: 0.0; color: "#8cfc1f" }
    //            GradientStop { position: 0.95; color: "#e8ff6e" }
    //        }
    //    }
    
    //--------------------------------------------------------------------------

    
    Item {
        id: bubble

        anchors {
            centerIn: parent
            horizontalCenterOffset: control.levelX
            verticalCenterOffset: control.levelY
        }

        width: parent.width * 0.3
        height: width

        Rectangle {
            anchors {
                fill: parent
            }

            radius: height / 2
            color: "#10808080"

//            border {
//                color: "#e8ff6e"
//                width: 3 * AppFramework.displayScaleFactor
//            }

//            opacity: 0.1
        }

        Rectangle {
            anchors {
                centerIn: parent
            }

            width: parent.width * 0.3
            height: 1 * AppFramework.displayScaleFactor
            color: "black"

        }

        Rectangle {
            anchors {
                centerIn: parent
            }

            height: parent.height * 0.3
            width: 1 * AppFramework.displayScaleFactor
            color: "black"
        }
    }
    
    //--------------------------------------------------------------------------
/*
    Item {
        anchors {
            fill: parent
            margins: parent.height * 0.2
        }

        Rectangle {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
            }

            color: "black"
            implicitHeight: 1 * AppFramework.displayScaleFactor

        }

        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                bottom: parent.bottom
            }

            color: "black"
            implicitWidth: 1 * AppFramework.displayScaleFactor

        }
    }
*/
    //--------------------------------------------------------------------------

    function toRadians(degrees) {
        return Math.PI * degrees / 180.0;
    }

    //--------------------------------------------------------------------------

}
