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
    enum DeductiveTier {
        Tier1_Local = 1,    // Single-cell clues & vertex degree constraints
        Tier2_Patterns = 2, // 2-cell patterns: 3-3, 3 next to 0, corners
        Tier3_Global = 3    // Global single loop & subloop avoidance (DSU)
    };

    // Solves puzzle with backtracking search and returns number of solutions found up to 'limit'
    static int solveCount(const SlitherlinkGrid &grid, const QVector<int> &clues, int limit = 2, QVector<int> *outSolution = nullptr);

    // Checks if the given line edges form a valid single loop satisfying all clues
    static bool isWinState(const SlitherlinkGrid &grid, const QVector<int> &clues, const QVector<int> &edges);

    // Solves deductively without guessing up to maxTier. Returns true if fully solved.
    static bool solveDeductive(const SlitherlinkGrid &grid, const QVector<int> &clues, int maxTier = Tier3_Global, QVector<int> *outEdges = nullptr);

    // Generates a verified unique-solution puzzle with 180° rotational symmetry and deduction tier grading
    static SlitherlinkPuzzle generatePuzzle(const Difficulty &difficulty, unsigned int seed = 0);
};
