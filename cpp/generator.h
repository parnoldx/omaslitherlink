#pragma once

#include "difficulty.h"
#include "slitherlink_types.h"

#include <QPair>
#include <QVector>

struct SlitherlinkPuzzle {
    int rows = 5;
    int cols = 5;
    QVector<int> clues;    // size rows * cols; -1 for empty, 0-3 for clues
    QVector<int> solution; // size numEdges; 1 for line, 0 for cross/empty
};

class SlitherlinkEngine {
public:
    // Solves puzzle and returns number of solutions found up to 'limit'
    static int solveCount(const SlitherlinkGrid &grid, const QVector<int> &clues, int limit = 2, QVector<int> *outSolution = nullptr);

    // Checks if the given line edges form a valid single loop satisfying all clues
    static bool isWinState(const SlitherlinkGrid &grid, const QVector<int> &clues, const QVector<int> &edges);

    // Generates a verified unique-solution puzzle
    static SlitherlinkPuzzle generatePuzzle(const Difficulty &difficulty, unsigned int seed = 0);
};
