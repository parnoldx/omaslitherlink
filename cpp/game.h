#pragma once

#include "difficulty.h"
#include "generator.h"
#include "slitherlink_types.h"
#include "storage.h"

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVector>


class SlitherlinkGame : public QObject {
    Q_OBJECT
    Q_PROPERTY(int rows READ rows NOTIFY boardChanged)
    Q_PROPERTY(int cols READ cols NOTIFY boardChanged)
    Q_PROPERTY(int numHEdges READ numHEdges NOTIFY boardChanged)
    Q_PROPERTY(int numVEdges READ numVEdges NOTIFY boardChanged)
    Q_PROPERTY(int totalEdges READ totalEdges NOTIFY boardChanged)
    Q_PROPERTY(QVariantList clues READ clues NOTIFY boardChanged)
    Q_PROPERTY(QVariantList edges READ edges NOTIFY edgesChanged)
    Q_PROPERTY(int cursorEdge READ cursorEdge NOTIFY cursorChanged)
    Q_PROPERTY(int points READ points NOTIFY scoreChanged)
    Q_PROPERTY(int factor READ factor NOTIFY factorChanged)
    Q_PROPERTY(int fails READ fails NOTIFY failsChanged)
    Q_PROPERTY(int time READ time NOTIFY timeChanged)
    Q_PROPERTY(QString formattedTime READ formattedTime NOTIFY timeChanged)
    Q_PROPERTY(QString difficultyKey READ difficultyKey NOTIFY gameStateChanged)
    Q_PROPERTY(QString difficultyLabel READ difficultyLabel NOTIFY gameStateChanged)
    Q_PROPERTY(bool isPaused READ isPaused NOTIFY gameStateChanged)
    Q_PROPERTY(bool inGame READ inGame NOTIFY gameStateChanged)
    Q_PROPERTY(bool canResume READ canResume NOTIFY canResumeChanged)
    Q_PROPERTY(int highscore READ highscore NOTIFY gameStateChanged)
    Q_PROPERTY(int basePoints READ basePoints NOTIFY gameStateChanged)
    Q_PROPERTY(int parTime READ parTime NOTIFY gameStateChanged)
    Q_PROPERTY(int timeBonus READ timeBonus NOTIFY timeChanged)
    Q_PROPERTY(int mistakeBonus READ mistakeBonus NOTIFY failsChanged)
    Q_PROPERTY(QString formattedParTime READ formattedParTime NOTIFY gameStateChanged)

public:
    explicit SlitherlinkGame(StorageManager *storage = nullptr, QObject *parent = nullptr);
    ~SlitherlinkGame() override;

    int rows() const { return m_grid.rows; }
    int cols() const { return m_grid.cols; }
    int numHEdges() const { return m_grid.numHEdges(); }
    int numVEdges() const { return m_grid.numVEdges(); }
    int totalEdges() const { return m_grid.numEdges(); }

    QVariantList clues() const;
    QVariantList edges() const;
    int cursorEdge() const { return m_cursorEdge; }
    int points() const;
    int factor() const { return m_factor; }
    int fails() const { return m_fails; }
    int time() const { return m_time; }
    QString formattedTime() const;
    QString difficultyKey() const { return m_difficulty.key; }
    QString difficultyLabel() const { return m_difficulty.label; }
    bool isPaused() const { return m_isPaused; }
    bool inGame() const { return m_inGame; }
    bool canResume() const;
    int highscore() const;

    int basePoints() const;
    int parTime() const;
    int timeBonus() const;
    int mistakeBonus() const;
    int calculateScore(int timeSeconds, int failsCount) const;
    QString formattedParTime() const;

    bool is_finished() const;

    // Direct access for testing
    const QVector<int> &solutionRaw() const { return m_solution; }
    const QVector<int> &edgesRaw() const { return m_edges; }
    const QVector<int> &cluesRaw() const { return m_clues; }
    void setFactorRaw(int f) { m_factor = f; }
    void setTimeRaw(int t) { m_time = t; }
    void setPointsRaw(int p) { m_points = p; }
    void setFailsRaw(int f) { m_fails = f; }
    void onSecondTick();
    void onWon();

public slots:
    void startNewGame(const QString &difficultyKey);
    void resumeGame();
    void pauseGame();
    void resumeTimer();
    void togglePause();
    void returnToMenu();
    void save_current_state();

    // Interaction slots
    void toggleEdge(int edgeIdx, int requestedState = -1);
    void setEdgeState(int edgeIdx, int state);
    void clickCellClue(int row, int col);
    void selectEdge(int edgeIdx);
    void moveCursor(int dRow, int dCol);
    bool isFinished() const;
    int getHighscoreFor(const QString &diffKey) const;

signals:
    void boardChanged();
    void edgesChanged();
    void cursorChanged();
    void scoreChanged();
    void factorChanged();
    void failsChanged();
    void timeChanged();
    void gameStateChanged();
    void canResumeChanged();
    void edgeFlash(int edgeIdx, bool isCorrect);
    void cellFlash(int row, int col, bool isCorrect);
    void cellCompleted(int row, int col);
    void gameWon(int points, int fails, int highscore, bool isNewRecord, int basePoints, int timeBonus, int mistakeBonus, const QString &parTimeStr);

private:
    void checkCellCompletions(int edgeIdx);

    StorageManager *m_storage = nullptr;
    bool m_ownsStorage = false;

    SlitherlinkGrid m_grid;
    Difficulty m_difficulty;
    QVector<int> m_clues;     // R*C
    QVector<int> m_solution;  // numEdges (1 or 0)
    QVector<int> m_edges;     // numEdges (0 empty, 1 line, 2 cross)

    int m_cursorEdge = 0;
    int m_points = 0;
    int m_factor = 28;
    int m_time = 0;
    int m_fails = 0;
    bool m_isPaused = false;
    bool m_inGame = false;

    QTimer m_timer;
};
