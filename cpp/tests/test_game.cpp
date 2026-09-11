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
    void testPause();
    void testWinDetection();
    void testStorage();
    void testUnpenalizedCrosses();
    void testSymmetryAndDeductions();
    void testTutorialMiniPuzzle();
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
    QCOMPARE(p.rows, 7);
    QCOMPARE(p.cols, 7);
    SlitherlinkGrid g{7, 7};
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
    // Easy initial projected score: 8000 base + 4500 time bonus + 2500 flawless = 15000
    QCOMPARE(game.basePoints(), 8000);
    QCOMPARE(game.parTime(), 180);
    QCOMPARE(game.points(), 15000);

    // Verify Model 1 score formula:
    QCOMPARE(game.calculateScore(0, 0), 15000);
    QCOMPARE(game.calculateScore(60, 0), 13500);  // 8000 + 120*25 + 2500
    QCOMPARE(game.calculateScore(190, 0), 10500); // 8000 + 0 + 2500 (over par)
    QCOMPARE(game.calculateScore(190, 1), 9000);  // 8000 + 0 + 1000
    QCOMPARE(game.calculateScore(190, 2), 8300);  // 8000 + 0 + 300
    QCOMPARE(game.calculateScore(190, 3), 8000);  // 8000 + 0 + 0
    QCOMPARE(game.calculateScore(190, 4), 7500);  // 8000 + 0 - 500
    QCOMPARE(game.calculateScore(190, 5), 7000);  // 8000 + 0 - 1000

    // Find a correct solution line edge and cross edge
    const auto &sol = game.solutionRaw();
    int solLineEdge = -1;
    int solCrossEdge = -1;
    for (int i = 0; i < sol.size(); ++i) {
        if (sol[i] == 1 && solLineEdge == -1) solLineEdge = i;
        if (sol[i] == 0 && solCrossEdge == -1) solCrossEdge = i;
    }
    QVERIFY(solLineEdge >= 0);
    QVERIFY(solCrossEdge >= 0);

    // Toggle correct line - drawn cleanly without jittery per-edge points
    game.toggleEdge(solLineEdge, 1);
    QCOMPARE(game.fails(), 0);
    QCOMPARE(game.edgesRaw()[solLineEdge], 1);

    // Toggle wrong line on an edge that shouldn't have a line - mistake penalty
    game.toggleEdge(solCrossEdge, 1);
    QCOMPARE(game.fails(), 1);
    QCOMPARE(game.edgesRaw()[solCrossEdge], 0); // Line not placed!
    // Flawless drops from +2500 to +1000 (-1500 difference)
    QCOMPARE(game.points(), 13500);

    // Place cross on scratchpad - unpenalized
    game.toggleEdge(solCrossEdge, 2);
    QCOMPARE(game.fails(), 1);
    QCOMPARE(game.edgesRaw()[solCrossEdge], 2);
    QCOMPARE(game.points(), 13500);
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

void TestSlitherlink::testUnpenalizedCrosses()
{
    QTemporaryDir tempDir;
    StorageManager storage(tempDir.path());
    SlitherlinkGame game(&storage);
    game.startNewGame(QStringLiteral("simple"));

    const auto &sol = game.solutionRaw();
    int solLineEdge = -1;
    for (int i = 0; i < sol.size(); ++i) {
        if (sol[i] == 1) { solLineEdge = i; break; }
    }
    QVERIFY(solLineEdge >= 0);

    // Right-clicking / marking cross on a solution line edge must NEVER fail or be blocked!
    QCOMPARE(game.fails(), 0);
    game.toggleEdge(solLineEdge, 2);
    QCOMPARE(game.fails(), 0); // Still 0 fails!
    QCOMPARE(game.edgesRaw()[solLineEdge], 2); // Placed as cross!

    // Drag-painting with setEdgeState is idempotent and does not toggle off:
    game.setEdgeState(solLineEdge, 2);
    QCOMPARE(game.edgesRaw()[solLineEdge], 2); // Still cross, not toggled to 0!
    QCOMPARE(game.fails(), 0);

    // Toggling cross again toggles it to empty (0) without fail:
    game.toggleEdge(solLineEdge, 2);
    QCOMPARE(game.edgesRaw()[solLineEdge], 0);
    QCOMPARE(game.fails(), 0);
}

void TestSlitherlink::testSymmetryAndDeductions()
{
    // Test Easy Bank puzzles (7x7): 180 symmetry & Tier 2 solvability
    int easyCount = PuzzleBank::count(QStringLiteral("easy"));
    QVERIFY(easyCount > 0);
    for (int i = 0; i < easyCount; ++i) {
        SlitherlinkPuzzle p = PuzzleBank::getPuzzle(QStringLiteral("easy"), i);
        QCOMPARE(p.rows, 7);
        QCOMPARE(p.cols, 7);
        SlitherlinkGrid g{p.rows, p.cols};
        for (int r = 0; r < p.rows; ++r) {
            for (int c = 0; c < p.cols; ++c) {
                int idx1 = r * p.cols + c;
                int idx2 = (p.rows - 1 - r) * p.cols + (p.cols - 1 - c);
                QCOMPARE(p.clues[idx1] >= 0, p.clues[idx2] >= 0);
            }
        }
        QVERIFY(SlitherlinkEngine::solveDeductive(g, p.clues, SlitherlinkEngine::Tier2_Patterns));
    }

    // Test Medium Bank puzzles (10x10): 180 symmetry & Tier 3 solvability
    int medCount = PuzzleBank::count(QStringLiteral("medium"));
    QVERIFY(medCount > 0);
    for (int i = 0; i < medCount; ++i) {
        SlitherlinkPuzzle p = PuzzleBank::getPuzzle(QStringLiteral("medium"), i);
        QCOMPARE(p.rows, 10);
        QCOMPARE(p.cols, 10);
        SlitherlinkGrid g{p.rows, p.cols};
        for (int r = 0; r < p.rows; ++r) {
            for (int c = 0; c < p.cols; ++c) {
                int idx1 = r * p.cols + c;
                int idx2 = (p.rows - 1 - r) * p.cols + (p.cols - 1 - c);
                QCOMPARE(p.clues[idx1] >= 0, p.clues[idx2] >= 0);
            }
        }
        QVERIFY(SlitherlinkEngine::solveDeductive(g, p.clues, SlitherlinkEngine::Tier3_Global));
    }

    // Test Hard Bank puzzles (15x15): 180 symmetry & Tier 3 solvability
    int hardCount = PuzzleBank::count(QStringLiteral("hard"));
    QVERIFY(hardCount > 0);
    for (int i = 0; i < hardCount; ++i) {
        SlitherlinkPuzzle p = PuzzleBank::getPuzzle(QStringLiteral("hard"), i);
        QCOMPARE(p.rows, 15);
        QCOMPARE(p.cols, 15);
        SlitherlinkGrid g{p.rows, p.cols};
        for (int r = 0; r < p.rows; ++r) {
            for (int c = 0; c < p.cols; ++c) {
                int idx1 = r * p.cols + c;
                int idx2 = (p.rows - 1 - r) * p.cols + (p.cols - 1 - c);
                QCOMPARE(p.clues[idx1] >= 0, p.clues[idx2] >= 0);
            }
        }
        QVERIFY(SlitherlinkEngine::solveDeductive(g, p.clues, SlitherlinkEngine::Tier3_Global));
    }

    // Test Master Bank puzzles (20x20): 180 symmetry & Tier 3 solvability
    int masterCount = PuzzleBank::count(QStringLiteral("master"));
    QVERIFY(masterCount > 0);
    for (int i = 0; i < masterCount; ++i) {
        SlitherlinkPuzzle p = PuzzleBank::getPuzzle(QStringLiteral("master"), i);
        QCOMPARE(p.rows, 20);
        QCOMPARE(p.cols, 20);
        SlitherlinkGrid g{p.rows, p.cols};
        for (int r = 0; r < p.rows; ++r) {
            for (int c = 0; c < p.cols; ++c) {
                int idx1 = r * p.cols + c;
                int idx2 = (p.rows - 1 - r) * p.cols + (p.cols - 1 - c);
                QCOMPARE(p.clues[idx1] >= 0, p.clues[idx2] >= 0);
            }
        }
        QVERIFY(SlitherlinkEngine::solveDeductive(g, p.clues, SlitherlinkEngine::Tier3_Global));
    }
}

void TestSlitherlink::testTutorialMiniPuzzle()
{
    // 3x3 grid geometry
    SlitherlinkGrid g{3, 3};
    QCOMPARE(g.numHEdges(), 12);
    QCOMPARE(g.numVEdges(), 12);
    QCOMPARE(g.numEdges(), 24);

    // Tutorial 3x3 puzzle clues
    QVector<int> clues = {
        2,  3, -1,
        2, -1,  0,
        3, -1,  0
    };

    // Verify deductive solvability
    QVERIFY(SlitherlinkEngine::solveDeductive(g, clues, SlitherlinkEngine::Tier3_Global));

    // Verify unique solution
    QVector<int> sol;
    int sols = SlitherlinkEngine::solveCount(g, clues, 2, &sol);
    QCOMPARE(sols, 1);

    // Verify solution edges match tutorial expectations
    const QVector<int> expectedSol = {0, 1, 4, 9, 12, 14, 16, 17, 20, 21};
    for (int e = 0; e < 24; ++e) {
        bool inExpected = expectedSol.contains(e);
        QCOMPARE(sol[e] == 1, inExpected);
    }

    // Verify isWinState returns true
    QVERIFY(SlitherlinkEngine::isWinState(g, clues, sol));

    // Verify Lesson 3 loop (2x2 grid): zero dead ends, all vertex degrees 0 or 2, cell (0,0) has 3 lines
    SlitherlinkGrid g2{2, 2};
    const QVector<int> lesson3Final = {1, 2, 2, 1, 1, 1, 1, 1, 2, 1, 2, 1};
    for (int vr = 0; vr <= g2.rows; ++vr) {
        for (int vc = 0; vc <= g2.cols; ++vc) {
            int deg = 0;
            for (int e : g2.vertEdges(vr, vc)) {
                if (lesson3Final[e] == 1) ++deg;
            }
            QVERIFY(deg == 0 || deg == 2);
        }
    }
    int cell0Lines = 0;
    for (int e : g2.cellEdges(0, 0)) {
        if (lesson3Final[e] == 1) ++cell0Lines;
    }
    QCOMPARE(cell0Lines, 3);
}

QTEST_MAIN(TestSlitherlink)
#include "test_game.moc"
