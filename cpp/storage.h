#pragma once

#include <QJsonObject>
#include <QString>
#include <QVariantMap>
#include <optional>

class StorageManager {
public:
    explicit StorageManager(const QString &baseDir = QString());

    QString baseDir() const { return m_baseDir; }

    bool hasSavedGame() const;
    void saveGame(const QJsonObject &state);
    std::optional<QJsonObject> loadGame() const;
    void deleteSavedGame();

    QVariantMap getAllHighscores() const;
    int getHighscore(const QString &difficultyKey) const;
    bool setHighscore(const QString &difficultyKey, int score);

private:
    QString m_baseDir;
    QString m_saveFile;
    QString m_highscoreFile;
};
