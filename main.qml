import QtQuick
import QtQuick.Window
import QtMultimedia

Window {
    id: root
    visible: true
    width: 960
    height: 540
    color: "black"

    MediaPlayer {
        id: mediaPlayer
        source: "file:///home/samna/dev/signage/videos/ecology-uhd-h264.mkv"
        videoOutput: videoOutput
        audioOutput: AudioOutput {}
        loops: MediaPlayer.Infinite

        onErrorOccurred: function(error, errorString) {
            console.error("Media player error:", error, errorString)
        }
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }

    // Keyboard controls
    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Space) {
                if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                    mediaPlayer.pause()
                } else {
                    mediaPlayer.play()
                }
            } else if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                Qt.quit()
            }
        }
    }

    Component.onCompleted: {
        mediaPlayer.play()
    }
}
