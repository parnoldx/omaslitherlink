#include "difficulty.h"
#include "game.h"
#include "generator.h"
#include "puzzle_bank.h"
#include "slitherlink_types.h"
#include "storage.h"

#include <QTemporaryDir>
#include <QTest>

class TestSlitherlink : public QObject {
    Q_OBJECT

private slots:
    void initTestCase();
    void testGridGeometry();
    void testSolverAndGenerator();
    void testPuzzleBank();
    void testGamePlayAndScoring();
    void testUndo();
    void testPause();
    void testWinDetection();
    void testStorage();
};

void TestSlitherlink::initTestCase()
{
}

void TestSlitherlink::testGridGeometry()
{
    SlitherlinkGrid g{5, 5};
    QCOMPARE(g.numCells(), 25);
    QCOMPARE(g.numVerts(), 36);
    QCOMPARE(g.numHEdges(), 30);
    QCOMPARE(g.numVEdges(), 30);
    QCOMPARE(g.numEdges(), 60);

    // Top-left cell edges
    auto c0 = g.cellEdges(0, 0);
    QCOMPARE(c0.size(), 4);
    QCOMPARE(c0[0], g.hEdge(0, 0)); // top
    QCOMPARE(c0[1], g.hEdge(1, 0)); // bottom
    QCOMPARE(c0[2], g.vEdge(0, 0)); // left
    QCOMPARE(c0[3], g.vEdge(0, 1)); // right

    // Endpoints
    auto [u, v] = g.edgeEndpoints(g.hEdge(0, 0));
    QCOMPARE(u, 0);
    QCOMPARE(v, 1);
}

void TestSlitherlink::testSolverAndGenerator()
{
    Difficulty easy = Difficulty::easy();
    SlitherlinkPuzzle p = SlitherlinkEngine::generatePuzzle(easy, 42);
    SlitherlinkGrid g{p.rows, p.cols};
    QCOMPARE(SlitherlinkEngine::solveCount(g, p.clues, 2), 1);
    QVERIFY(SlitherlinkEngine::isWinState(g, p.clues, p.solution));
}

void TestSlitherlink::testPuzzleBank()
{
    QVERIFY(PuzzleBank::count(QStringLiteral("easy")) > 0);
    QVERIFY(PuzzleBank::count(QStringLiteral("medium")) > 0);
    QVERIFY(PuzzleBank::count(QStringLiteral("hard")) > 0);

    SlitherlinkPuzzle p = PuzzleBank::getPuzzle(QStringLiteral("easy"), 0);
    QCOMPARE(p.rows, 5);
    QCOMPARE(p.cols, 5);
    SlitherlinkGrid g{5, 5};
    QCOMPARE(p.solution.size(), g.numEdges());
    QVERIFY(SlitherlinkEngine::isWinState(g, p.clues, p.solution));
}

void TestSlitherlink::testGamePlayAndScoring()
{
    QTemporaryDir tempDir;
    StorageManager storage(tempDir.path());
    SlitherlinkGame game(&storage);

    game.startNewGame(QStringLiteral("simple"));
    QVERIFY(game.inGame());
    QCOMPARE(game.fails(), 0);
    QCOMPARE(game.points(), 0);
    QCOMPARE(game.factor(), 28);

    // Find a correct solution line edge
    const auto &sol = game.solutionRaw();
    int solLineEdge = -1;
    int solCrossEdge = -1;
    for (int i = 0; i < sol.size(); ++i) {
        if (sol[i] == 1 && solLineEdge == -1) solLineEdge = i;
        if (sol[i] == 0 && solCrossEdge == -1) solCrossEdge = i;
    }
    QVERIFY(solLineEdge >= 0);
    QVERIFY(solCrossEdge >= 0);

    // Toggle correct line
    game.toggleEdge(solLineEdge, 1);
    QVERIFY(game.points() > 0);
    QCOMPARE(game.fails(), 0);
    QCOMPARE(game.edgesRaw()[solLineEdge], 1);

    // Toggle wrong line on an edge that shouldn't have a line
    game.toggleEdge(solCrossEdge, 1);
    QCOMPARE(game.fails(), 1);
    QCOMPARE(game.edgesRaw()[solCrossEdge], 0); // Not placed!

    // Place correct cross
    game.toggleEdge(solCrossEdge, 2);
    QCOMPARE(game.fails(), 1);
    QCOMPARE(game.edgesRaw()[solCrossEdge], 2);
}

void TestSlitherlink::testUndo()
{
    QTemporaryDir tempDir;
    StorageManager storage(tempDir.path());
    SlitherlinkGame game(&storage);
    game.startNewGame(QStringLiteral("simple"));

    const auto &sol = game.solutionRaw();
    int lineEdge = -1;
    for (int i = 0; i < sol.size(); ++i) {
        if (sol[i] == 1) { lineEdge = i; break; }
    }

    int startPts = game.points();
    game.toggleEdge(lineEdge, 1);
    QCOMPARE(game.edgesRaw()[lineEdge], 1);
    QVERIFY(game.points() > startPts);

    game.undo();
    QCOMPARE(game.edgesRaw()[lineEdge], 0);
    QCOMPARE(game.points(), startPts);
}

void TestSlitherlink::testPause()
{
    QTemporaryDir tempDir;
    StorageManager storage(tempDir.path());
    SlitherlinkGame game(&storage);
    game.startNewGame(QStringLiteral("simple"));

    QVERIFY(!game.isPaused());
    game.togglePause();
    QVERIFY(game.isPaused());
    game.togglePause();
    QVERIFY(!game.isPaused());
}

void TestSlitherlink::testWinDetection()
{
    QTemporaryDir tempDir;
    StorageManager storage(tempDir.path());
    SlitherlinkGame game(&storage);
    game.startNewGame(QStringLiteral("simple"));

    const auto sol = game.solutionRaw();
    // Simulate setting all solution edges
    for (int i = 0; i < sol.size(); ++i) {
        if (sol[i] == 1) {
            game.toggleEdge(i, 1);
        }
    }

    QVERIFY(!game.inGame()); // gameWon emitted and inGame set to false!
}

void TestSlitherlink::testStorage()
{
    QTemporaryDir tempDir;
    StorageManager storage(tempDir.path());

    QCOMPARE(storage.hasSavedGame(), false);
    QCOMPARE(storage.getHighscore(QStringLiteral("simple")), 0);

    QVERIFY(storage.setHighscore(QStringLiteral("simple"), 1500));
    QCOMPARE(storage.getHighscore(QStringLiteral("simple")), 1500);

    // Setting a lower score shouldn't overwrite
    QVERIFY(!storage.setHighscore(QStringLiteral("simple"), 1200));
    QCOMPARE(storage.getHighscore(QStringLiteral("simple")), 1500);
}

QTEST_MAIN(TestSlitherlink)
#include "test_game.moc"
