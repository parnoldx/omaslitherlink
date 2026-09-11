#include "game.h"
#include "puzzle_bank.h"

#include <QJsonArray>
#include <QJsonObject>
#include <algorithm>

SlitherlinkGame::SlitherlinkGame(StorageManager *storage, QObject *parent)
    : QObject(parent)
    , m_difficulty(Difficulty::easy())
{
    if (storage) {
        m_storage = storage;
        m_ownsStorage = false;
    } else {
        m_storage = new StorageManager();
        m_ownsStorage = true;
    }

    m_grid.rows = 5;
    m_grid.cols = 5;
    m_clues.fill(-1, m_grid.numCells());
    m_solution.fill(0, m_grid.numEdges());
    m_edges.fill(0, m_grid.numEdges());

    m_timer.setInterval(1000);
    connect(&m_timer, &QTimer::timeout, this, &SlitherlinkGame::onSecondTick);
}

SlitherlinkGame::~SlitherlinkGame()
{
    if (m_ownsStorage)
        delete m_storage;
}

void SlitherlinkGame::onSecondTick()
{
    if (m_isPaused || !m_inGame)
        return;
    ++m_time;
    emit timeChanged();

    if (m_time % TIME_FACTOR_REDUCE == 0 && m_factor > 1) {
        --m_factor;
        emit factorChanged();
    }
}

void SlitherlinkGame::startNewGame(const QString &difficultyKey)
{
    m_difficulty = Difficulty::fromKey(difficultyKey);
    m_grid.rows = m_difficulty.rows;
    m_grid.cols = m_difficulty.cols;

    const SlitherlinkPuzzle p = PuzzleBank::getPuzzle(m_difficulty.key);
    m_clues = p.clues;
    m_solution = p.solution;
    m_edges.fill(0, m_grid.numEdges());
    m_history.clear();

    m_factor = m_difficulty.factor;
    m_points = 0;
    m_time = 0;
    m_fails = 0;
    m_isPaused = false;
    m_inGame = true;
    m_cursorEdge = 0;

    m_timer.start();

    emit boardChanged();
    emit edgesChanged();
    emit cursorChanged();
    emit scoreChanged();
    emit factorChanged();
    emit failsChanged();
    emit timeChanged();
    emit gameStateChanged();
    m_storage->deleteSavedGame();
    emit canResumeChanged();
}

void SlitherlinkGame::resumeGame()
{
    auto dataOpt = m_storage->loadGame();
    if (!dataOpt)
        return;
    const QJsonObject data = *dataOpt;

    m_difficulty = Difficulty::fromKey(data.value(QStringLiteral("difficulty")).toString(QStringLiteral("simple")));
    m_grid.rows = data.value(QStringLiteral("rows")).toInt(m_difficulty.rows);
    m_grid.cols = data.value(QStringLiteral("cols")).toInt(m_difficulty.cols);

    const QJsonArray cluesArr = data.value(QStringLiteral("clues")).toArray();
    const QJsonArray solArr = data.value(QStringLiteral("solution")).toArray();
    const QJsonArray edgesArr = data.value(QStringLiteral("edges")).toArray();

    m_clues.resize(m_grid.numCells());
    for (int i = 0; i < m_grid.numCells() && i < cluesArr.size(); ++i)
        m_clues[i] = cluesArr[i].toInt();

    m_solution.resize(m_grid.numEdges());
    for (int i = 0; i < m_grid.numEdges() && i < solArr.size(); ++i)
        m_solution[i] = solArr[i].toInt();

    m_edges.resize(m_grid.numEdges());
    for (int i = 0; i < m_grid.numEdges() && i < edgesArr.size(); ++i)
        m_edges[i] = edgesArr[i].toInt();

    m_factor = data.value(QStringLiteral("factor")).toInt(m_difficulty.factor);
    m_points = data.value(QStringLiteral("points")).toInt(0);
    m_time = data.value(QStringLiteral("time")).toInt(0);
    m_fails = data.value(QStringLiteral("fails")).toInt(0);

    m_cursorEdge = 0;
    m_isPaused = false;
    m_inGame = true;
    m_history.clear();

    m_timer.start();

    emit boardChanged();
    emit edgesChanged();
    emit cursorChanged();
    emit scoreChanged();
    emit factorChanged();
    emit failsChanged();
    emit timeChanged();
    emit gameStateChanged();
}

void SlitherlinkGame::pauseGame()
{
    m_isPaused = true;
    m_timer.stop();
    emit gameStateChanged();
}

void SlitherlinkGame::resumeTimer()
{
    if (m_inGame && m_isPaused) {
        m_isPaused = false;
        m_timer.start();
        emit gameStateChanged();
    }
}

void SlitherlinkGame::togglePause()
{
    if (m_isPaused)
        resumeTimer();
    else
        pauseGame();
}

void SlitherlinkGame::returnToMenu()
{
    if (m_inGame && !is_finished()) {
        pauseGame();
        save_current_state();
    }
}

void SlitherlinkGame::save_current_state()
{
    if (!m_inGame || is_finished())
        return;

    bool hasMoves = false;
    for (int v : m_edges) {
        if (v != 0) {
            hasMoves = true;
            break;
        }
    }
    if (!hasMoves && m_time < 5)
        return;

    QJsonObject state;
    state.insert(QStringLiteral("difficulty"), m_difficulty.key);
    state.insert(QStringLiteral("rows"), m_grid.rows);
    state.insert(QStringLiteral("cols"), m_grid.cols);

    QJsonArray cluesArr;
    for (int c : m_clues) cluesArr.append(c);
    state.insert(QStringLiteral("clues"), cluesArr);

    QJsonArray solArr;
    for (int s : m_solution) solArr.append(s);
    state.insert(QStringLiteral("solution"), solArr);

    QJsonArray edgesArr;
    for (int e : m_edges) edgesArr.append(e);
    state.insert(QStringLiteral("edges"), edgesArr);

    state.insert(QStringLiteral("factor"), m_factor);
    state.insert(QStringLiteral("points"), m_points);
    state.insert(QStringLiteral("time"), m_time);
    state.insert(QStringLiteral("fails"), m_fails);

    m_storage->saveGame(state);
    emit canResumeChanged();
}

void SlitherlinkGame::toggleEdge(int edgeIdx, int requestedState)
{
    if (!m_inGame || m_isPaused || edgeIdx < 0 || edgeIdx >= m_grid.numEdges())
        return;

    m_cursorEdge = edgeIdx;
    emit cursorChanged();

    const int curr = m_edges[edgeIdx];
    int target = 0;

    if (requestedState == -1) {
        // Default toggle: Empty/Cross -> Line; Line -> Empty
        target = (curr == 1) ? 0 : 1;
    } else if (requestedState == 2) {
        // Cross toggle: Empty/Line -> Cross; Cross -> Empty
        target = (curr == 2) ? 0 : 2;
    } else {
        target = (curr == requestedState) ? 0 : requestedState;
    }

    if (target == 1) {
        // Trying to set Line
        if (m_solution[edgeIdx] == 1) {
            int pts = POINTS_LINE * m_factor;
            SlitherlinkHistoryEntry entry{edgeIdx, curr, pts};
            m_history.append(entry);

            m_edges[edgeIdx] = 1;
            m_points += pts;

            emit edgeFlash(edgeIdx, true);
            emit edgesChanged();
            emit scoreChanged();

            checkCellCompletions(edgeIdx);

            if (is_finished()) {
                onWon();
            } else {
                save_current_state();
            }
        } else {
            ++m_fails;
            emit failsChanged();
            emit edgeFlash(edgeIdx, false);
        }
    } else if (target == 2) {
        // Trying to set Cross
        if (m_solution[edgeIdx] == 1) {
            // Cannot cross a solution line!
            ++m_fails;
            emit failsChanged();
            emit edgeFlash(edgeIdx, false);
        } else {
            SlitherlinkHistoryEntry entry{edgeIdx, curr, 0};
            m_history.append(entry);

            m_edges[edgeIdx] = 2;
            emit edgeFlash(edgeIdx, true);
            emit edgesChanged();
            save_current_state();
        }
    } else {
        // Clearing to Empty
        int ptsDeducted = (curr == 1) ? POINTS_LINE * m_factor : 0;
        SlitherlinkHistoryEntry entry{edgeIdx, curr, -ptsDeducted};
        m_history.append(entry);

        m_edges[edgeIdx] = 0;
        m_points = qMax(0, m_points - ptsDeducted);

        emit edgesChanged();
        emit scoreChanged();
        save_current_state();
    }
}

void SlitherlinkGame::setEdgeState(int edgeIdx, int state)
{
    toggleEdge(edgeIdx, state);
}

void SlitherlinkGame::clickCellClue(int row, int col)
{
    if (!m_inGame || m_isPaused || row < 0 || row >= m_grid.rows || col < 0 || col >= m_grid.cols)
        return;

    const int clue = m_clues[row * m_grid.cols + col];
    if (clue < 0)
        return;

    const auto cellEdges = m_grid.cellEdges(row, col);

    if (clue == 0) {
        bool changed = false;
        for (int e : cellEdges) {
            if (m_edges[e] == 0) {
                m_edges[e] = 2;
                m_history.append({e, 0, 0});
                changed = true;
            }
        }
        if (changed) {
            emit cellFlash(row, col, true);
            emit edgesChanged();
            save_current_state();
        }
        return;
    }

    // If clue is satisfied, cross out remaining edges
    int lines = 0;
    for (int e : cellEdges) {
        if (m_edges[e] == 1) ++lines;
    }
    if (lines == clue) {
        bool changed = false;
        for (int e : cellEdges) {
            if (m_edges[e] == 0) {
                m_edges[e] = 2;
                m_history.append({e, 0, 0});
                changed = true;
            }
        }
        if (changed) {
            emit cellFlash(row, col, true);
            emit edgesChanged();
            save_current_state();
        }
    }
}

void SlitherlinkGame::checkCellCompletions(int edgeIdx)
{
    const auto adjacent = m_grid.adjacentCells(edgeIdx);
    for (int cIdx : adjacent) {
        const int r = cIdx / m_grid.cols;
        const int c = cIdx % m_grid.cols;
        const int clue = m_clues[cIdx];
        if (clue <= 0) continue;

        const auto ce = m_grid.cellEdges(r, c);
        int lineCount = 0;
        for (int e : ce) {
            if (m_edges[e] == 1) ++lineCount;
        }
        if (lineCount == clue) {
            const int bonus = (clue + 1) * POINTS_CELL_COMPLETE * m_factor;
            m_points += bonus;
            emit cellCompleted(r, c);
            emit scoreChanged();

            // Auto-cross remaining empty edges around satisfied clue cell
            for (int e : ce) {
                if (m_edges[e] == 0 && m_solution[e] == 0) {
                    m_edges[e] = 2;
                }
            }
            emit edgesChanged();
        }
    }
}

void SlitherlinkGame::selectEdge(int edgeIdx)
{
    if (edgeIdx >= 0 && edgeIdx < m_grid.numEdges()) {
        m_cursorEdge = edgeIdx;
        emit cursorChanged();
    }
}

void SlitherlinkGame::moveCursor(int dRow, int dCol)
{
    const auto coord = m_grid.edgeCoord(m_cursorEdge);
    int r = coord.row;
    int c = coord.col;
    bool isVert = coord.isVertical;

    if (dRow != 0) {
        if (!isVert) {
            // Horizontal edge: moving up/down changes row or switches to vertical
            int nextRow = qBound(0, r + dRow, m_grid.rows);
            m_cursorEdge = m_grid.hEdge(nextRow, c);
        } else {
            // Vertical edge: move up/down
            int nextRow = qBound(0, r + dRow, m_grid.rows - 1);
            m_cursorEdge = m_grid.vEdge(nextRow, c);
        }
    } else if (dCol != 0) {
        if (isVert) {
            int nextCol = qBound(0, c + dCol, m_grid.cols);
            m_cursorEdge = m_grid.vEdge(r, nextCol);
        } else {
            int nextCol = qBound(0, c + dCol, m_grid.cols - 1);
            m_cursorEdge = m_grid.hEdge(r, nextCol);
        }
    }
    emit cursorChanged();
}

void SlitherlinkGame::undo()
{
    if (m_history.isEmpty())
        return;

    const auto last = m_history.takeLast();
    if (last.edgeIdx >= 0 && last.edgeIdx < m_grid.numEdges()) {
        m_edges[last.edgeIdx] = last.prevState;
        m_points = qMax(0, m_points - last.pointsAdded);
        m_cursorEdge = last.edgeIdx;

        emit edgesChanged();
        emit scoreChanged();
        emit cursorChanged();
        save_current_state();
    }
}

bool SlitherlinkGame::is_finished() const
{
    return SlitherlinkEngine::isWinState(m_grid, m_clues, m_edges);
}

bool SlitherlinkGame::isFinished() const
{
    return is_finished();
}

void SlitherlinkGame::onWon()
{
    m_timer.stop();
    m_inGame = false;
    m_storage->deleteSavedGame();
    emit canResumeChanged();

    bool isNewRecord = false;
    if (m_fails <= 3)
        isNewRecord = m_storage->setHighscore(m_difficulty.key, m_points);

    const int currentHs = m_storage->getHighscore(m_difficulty.key);
    emit gameWon(m_points, m_fails, currentHs, isNewRecord);
    emit gameStateChanged();
}

QVariantList SlitherlinkGame::clues() const
{
    QVariantList list;
    list.reserve(m_clues.size());
    for (int c : m_clues) list.append(c);
    return list;
}

QVariantList SlitherlinkGame::edges() const
{
    QVariantList list;
    list.reserve(m_edges.size());
    for (int e : m_edges) list.append(e);
    return list;
}

QString SlitherlinkGame::formattedTime() const
{
    const int minutes = m_time / 60;
    const int seconds = m_time % 60;
    return QStringLiteral("%1:%2")
        .arg(minutes, 2, 10, QLatin1Char('0'))
        .arg(seconds, 2, 10, QLatin1Char('0'));
}

bool SlitherlinkGame::canResume() const
{
    return m_storage->hasSavedGame();
}

int SlitherlinkGame::highscore() const
{
    return m_storage->getHighscore(m_difficulty.key);
}

int SlitherlinkGame::getHighscoreFor(const QString &diffKey) const
{
    return m_storage->getHighscore(diffKey);
}
