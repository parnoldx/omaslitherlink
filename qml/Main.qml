import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 840
    height: 820
    minimumWidth: 480
    minimumHeight: 540
    title: "Slitherlink"
    color: theme.background

    // Current view state: "welcome", "game", "win"
    property string currentView: "welcome"

    Shortcut {
        sequence: "Escape"
        enabled: window.currentView === "game" || window.currentView === "tutorial"
        onActivated: {
            if (window.currentView === "game") game.returnToMenu();
            window.currentView = "welcome";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header Bar
        HeaderBar {
            id: headerBar
            visible: window.currentView !== "welcome" && window.currentView !== "tutorial"
            Layout.fillWidth: true
            Layout.preferredHeight: (window.currentView === "welcome" || window.currentView === "tutorial") ? 0 : 68
            Layout.minimumHeight: (window.currentView === "welcome" || window.currentView === "tutorial") ? 0 : 68
            onGoHome: {
                game.returnToMenu();
                window.currentView = "welcome";
            }
            onNewGame: {
                game.returnToMenu();
                window.currentView = "welcome";
            }
        }

        // View Stack
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Welcome View
            WelcomeView {
                id: welcomeView
                anchors.fill: parent
                visible: window.currentView === "welcome"
                onOpenTutorial: {
                    window.currentView = "tutorial";
                    tutorialView.forceActiveFocus();
                }
                onStartGame: function(diffKey) {
                    game.startNewGame(diffKey);
                    window.currentView = "game";
                    boardView.forceActiveFocus();
                }
                onResumeGame: {
                    game.resumeGame();
                    window.currentView = "game";
                    boardView.forceActiveFocus();
                }
            }

            // Tutorial View
            TutorialView {
                id: tutorialView
                anchors.fill: parent
                visible: window.currentView === "tutorial"
                onExitTutorial: {
                    window.currentView = "welcome";
                }
                onStartGame: function(diffKey) {
                    game.startNewGame(diffKey);
                    window.currentView = "game";
                    boardView.forceActiveFocus();
                }
            }

            // Game View
            BoardView {
                id: boardView
                anchors.fill: parent
                visible: window.currentView === "game"
                onReturnToMenu: {
                    window.currentView = "welcome";
                }
            }

            // Win View
            WinView {
                id: winView
                anchors.fill: parent
                visible: window.currentView === "win"
                onPlayAgain: {
                    game.startNewGame(game.difficultyKey);
                    window.currentView = "game";
                    boardView.forceActiveFocus();
                }
                onReturnToMenu: {
                    window.currentView = "welcome";
                }
            }
        }
    }

    // Connect game win signal
    Connections {
        target: game

        function onGameWon(points, fails, highscore, isNewRecord, basePoints, timeBonus, mistakeBonus, parTimeStr) {
            winView.finalPoints = points;
            winView.finalFails = fails;
            winView.currentHighscore = highscore;
            winView.isRecord = isNewRecord;
            winView.finalTime = game.formattedTime;
            winView.basePoints = basePoints;
            winView.timeBonus = timeBonus;
            winView.mistakeBonus = mistakeBonus;
            winView.parTimeStr = parTimeStr;
            window.currentView = "win";
        }
    }
}
