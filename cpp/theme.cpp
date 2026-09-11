#include "theme.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QTextStream>

OmarchyTheme::OmarchyTheme(QObject *parent)
    : QObject(parent)
{
    m_themeDir = QDir::homePath() + QStringLiteral("/.local/state/omarchy/current/theme");
    m_colorsFile = m_themeDir + QStringLiteral("/colors.toml");
    m_currentDir = QFileInfo(QDir(m_themeDir).absolutePath()).absolutePath(); // .../current

    loadTheme();

    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString &) {
        loadTheme();
        setupWatcher();
    });
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this](const QString &) {
        loadTheme();
        setupWatcher();
    });
    setupWatcher();
}

void OmarchyTheme::setupWatcher()
{
    const QStringList watchedFiles = m_watcher.files();
    const QStringList watchedDirs = m_watcher.directories();
    for (const QString &path : {m_currentDir, m_themeDir, m_colorsFile}) {
        if (QFileInfo::exists(path)
            && !watchedFiles.contains(path)
            && !watchedDirs.contains(path)) {
            m_watcher.addPath(path);
        }
    }
}

static QString parseTomlString(const QString &content, const QString &key, const QString &fallback)
{
    const QRegularExpression re(
        QStringLiteral("^\\s*%1\\s*=\\s*[\"']([^\"']*)[\"']").arg(QRegularExpression::escape(key)),
        QRegularExpression::MultilineOption);
    const auto m = re.match(content);
    if (m.hasMatch())
        return m.captured(1);
    return fallback;
}

void OmarchyTheme::loadTheme()
{
    QFile f(m_colorsFile);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    const QString content = QString::fromUtf8(f.readAll());
    m_mode = parseTomlString(content, QStringLiteral("mode"), m_mode);
    m_accent = parseTomlString(content, QStringLiteral("accent"), m_accent);
    m_background = parseTomlString(content, QStringLiteral("background"), m_background);
    m_darkBackground = parseTomlString(content, QStringLiteral("dark_background"), m_darkBackground);
    m_darkerBackground = parseTomlString(content, QStringLiteral("darker_background"), m_darkerBackground);
    m_lighterBackground = parseTomlString(content, QStringLiteral("lighter_background"), m_lighterBackground);
    m_foreground = parseTomlString(content, QStringLiteral("foreground"), m_foreground);
    m_darkForeground = parseTomlString(content, QStringLiteral("dark_foreground"), m_darkForeground);
    m_lightForeground = parseTomlString(content, QStringLiteral("light_foreground"), m_lightForeground);
    m_muted = parseTomlString(content, QStringLiteral("muted"), m_muted);
    m_selection = parseTomlString(content, QStringLiteral("selection"), m_selection);
    m_red = parseTomlString(content, QStringLiteral("red"), m_red);
    m_green = parseTomlString(content, QStringLiteral("green"), m_green);
    m_yellow = parseTomlString(content, QStringLiteral("yellow"), m_yellow);
    m_orange = parseTomlString(content, QStringLiteral("orange"), m_orange);
    m_blue = parseTomlString(content, QStringLiteral("blue"), m_blue);
    m_cyan = parseTomlString(content, QStringLiteral("cyan"), m_cyan);
    m_magenta = parseTomlString(content, QStringLiteral("magenta"), m_magenta);

    emit themeChanged();
}
