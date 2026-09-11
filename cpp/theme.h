#pragma once

#include <QColor>
#include <QFileSystemWatcher>
#include <QObject>
#include <QString>

class OmarchyTheme : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString mode READ mode NOTIFY themeChanged)
    Q_PROPERTY(QColor accent READ accent NOTIFY themeChanged)
    Q_PROPERTY(QColor background READ background NOTIFY themeChanged)
    Q_PROPERTY(QColor darkBackground READ darkBackground NOTIFY themeChanged)
    Q_PROPERTY(QColor darkerBackground READ darkerBackground NOTIFY themeChanged)
    Q_PROPERTY(QColor lighterBackground READ lighterBackground NOTIFY themeChanged)
    Q_PROPERTY(QColor foreground READ foreground NOTIFY themeChanged)
    Q_PROPERTY(QColor darkForeground READ darkForeground NOTIFY themeChanged)
    Q_PROPERTY(QColor lightForeground READ lightForeground NOTIFY themeChanged)
    Q_PROPERTY(QColor muted READ muted NOTIFY themeChanged)
    Q_PROPERTY(QColor selection READ selection NOTIFY themeChanged)
    Q_PROPERTY(QColor red READ red NOTIFY themeChanged)
    Q_PROPERTY(QColor green READ green NOTIFY themeChanged)
    Q_PROPERTY(QColor yellow READ yellow NOTIFY themeChanged)
    Q_PROPERTY(QColor orange READ orange NOTIFY themeChanged)
    Q_PROPERTY(QColor blue READ blue NOTIFY themeChanged)
    Q_PROPERTY(QColor cyan READ cyan NOTIFY themeChanged)
    Q_PROPERTY(QColor magenta READ magenta NOTIFY themeChanged)

public:
    explicit OmarchyTheme(QObject *parent = nullptr);

    QString mode() const { return m_mode; }
    QColor accent() const { return QColor(m_accent); }
    QColor background() const { return QColor(m_background); }
    QColor darkBackground() const { return QColor(m_darkBackground); }
    QColor darkerBackground() const { return QColor(m_darkerBackground); }
    QColor lighterBackground() const { return QColor(m_lighterBackground); }
    QColor foreground() const { return QColor(m_foreground); }
    QColor darkForeground() const { return QColor(m_darkForeground); }
    QColor lightForeground() const { return QColor(m_lightForeground); }
    QColor muted() const { return QColor(m_muted); }
    QColor selection() const { return QColor(m_selection); }
    QColor red() const { return QColor(m_red); }
    QColor green() const { return QColor(m_green); }
    QColor yellow() const { return QColor(m_yellow); }
    QColor orange() const { return QColor(m_orange); }
    QColor blue() const { return QColor(m_blue); }
    QColor cyan() const { return QColor(m_cyan); }
    QColor magenta() const { return QColor(m_magenta); }

    void loadTheme();

signals:
    void themeChanged();

private:
    void setupWatcher();

    QString m_themeDir;
    QString m_colorsFile;
    QString m_currentDir;
    QFileSystemWatcher m_watcher;

    QString m_mode = QStringLiteral("dark");
    QString m_accent = QStringLiteral("#81a1c1");
    QString m_background = QStringLiteral("#2e3440");
    QString m_darkBackground = QStringLiteral("#222730");
    QString m_darkerBackground = QStringLiteral("#191c23");
    QString m_lighterBackground = QStringLiteral("#3b4252");
    QString m_foreground = QStringLiteral("#d8dee9");
    QString m_darkForeground = QStringLiteral("#667080");
    QString m_lightForeground = QStringLiteral("#adb5c4");
    QString m_muted = QStringLiteral("#4c566a");
    QString m_selection = QStringLiteral("#434c5e");
    QString m_red = QStringLiteral("#bf616a");
    QString m_green = QStringLiteral("#a3be8c");
    QString m_yellow = QStringLiteral("#ebcb8b");
    QString m_orange = QStringLiteral("#d5967a");
    QString m_blue = QStringLiteral("#81a1c1");
    QString m_cyan = QStringLiteral("#88c0d0");
    QString m_magenta = QStringLiteral("#b48ead");
};
