#pragma once

#include "generator.h"
#include <QString>

class PuzzleBank {
public:
    static SlitherlinkPuzzle getPuzzle(const QString &difficultyKey, int index = -1);
    static int count(const QString &difficultyKey);
};
