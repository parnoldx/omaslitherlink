#include "game.h"
#include "theme.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QIcon>
#include <QImage>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>
#include <QUrl>
#include <csignal>

static QString findQmlMain(const QString &appDir)
{
    const QStringList candidates = {
        appDir + QStringLiteral("/qml/Main.qml"),
        appDir + QStringLiteral("/../qml/Main.qml"),
        appDir + QStringLiteral("/../../qml/Main.qml"),
        QDir::cleanPath(appDir + QStringLiteral("/../share/omarchy-slitherlink/qml/Main.qml")),
    };
    for (const QString &c : candidates) {
        if (QFileInfo::exists(c))
            return QFileInfo(c).absoluteFilePath();
    }
    const QByteArray appdirEnv = qgetenv("OMARCHY_SLITHERLINK_ROOT");
    if (!appdirEnv.isEmpty()) {
        const QString p = QString::fromLocal8Bit(appdirEnv) + QStringLiteral("/qml/Main.qml");
        if (QFileInfo::exists(p))
            return QFileInfo(p).absoluteFilePath();
    }
    return {};
}

int main(int argc, char *argv[])
{
    std::signal(SIGINT, SIG_DFL);

    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM"))
        qputenv("QT_QPA_PLATFORM", "wayland;xcb");

    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("Omarchy"));
    app.setApplicationName(QStringLiteral("Slitherlink"));
    app.setDesktopFileName(QStringLiteral("org.omarchy.slitherlink"));

    const QString appDir = QCoreApplication::applicationDirPath();
    const QString iconPath = [&]() {
        const QStringList icons = {
            appDir + QStringLiteral("/data/org.omarchy.slitherlink.svg"),
            appDir + QStringLiteral("/../data/org.omarchy.slitherlink.svg"),
            appDir + QStringLiteral("/../../data/org.omarchy.slitherlink.svg"),
        };
        for (const QString &p : icons) {
            if (QFileInfo::exists(p))
                return QFileInfo(p).absoluteFilePath();
        }
        return QString();
    }();
    if (!iconPath.isEmpty())
        app.setWindowIcon(QIcon(iconPath));

    OmarchyTheme theme;
    SlitherlinkGame game;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("theme"), &theme);
    engine.rootContext()->setContextProperty(QStringLiteral("game"), &game);

    QObject::connect(&app, &QGuiApplication::aboutToQuit, &game, [&game]() {
        if (game.inGame() && !game.is_finished()) {
            game.save_current_state();
        }
    });

    const QString qmlFile = findQmlMain(appDir);
    if (qmlFile.isEmpty()) {
        qCritical("Error: Could not find qml/Main.qml near the binary.");
        return 1;
    }
    engine.load(QUrl::fromLocalFile(qmlFile));
    if (engine.rootObjects().isEmpty()) {
        qCritical("Error: Could not load QML user interface.");
        return 1;
    }

    // Docs screenshot: OMARCHY_SLITHERLINK_SCREENSHOT=/path/ingame.png
    const QString shotPath = QString::fromLocal8Bit(qgetenv("OMARCHY_SLITHERLINK_SCREENSHOT"));
    if (!shotPath.isEmpty()) {
        QObject *root = engine.rootObjects().constFirst();
        root->setProperty("currentView", QStringLiteral("game"));
        game.startNewGame(QStringLiteral("easy"));

        // Make a few valid moves so the screenshot shows active lines and score
        int linesPlaced = 0;
        for (int i = 0; i < game.totalEdges(); ++i) {
            if (game.solutionRaw()[i] == 1) {
                game.toggleEdge(i, 1);
                if (++linesPlaced >= 6) break;
            }
        }
        // Also auto-cross a 0 if present
        for (int r = 0; r < game.rows(); ++r) {
            for (int c = 0; c < game.cols(); ++c) {
                if (game.clues()[r * game.cols() + c].toInt() == 0) {
                    game.clickCellClue(r, c);
                    break;
                }
            }
        }

        QTimer::singleShot(900, &app, [root, shotPath]() {
            auto *win = qobject_cast<QQuickWindow *>(root);
            if (!win) {
                qCritical("Screenshot: root is not a QQuickWindow");
                QCoreApplication::exit(1);
                return;
            }
            const QImage img = win->grabWindow();
            if (img.isNull() || !img.save(shotPath)) {
                qCritical("Screenshot: failed to write %s", qPrintable(shotPath));
                QCoreApplication::exit(1);
                return;
            }
            qInfo("Wrote screenshot %s", qPrintable(shotPath));
            QCoreApplication::exit(0);
        });
    }

    return app.exec();
}
