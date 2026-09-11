#include "difficulty.h"

static const Difficulty s_easy = {
    QStringLiteral("simple"),
    QStringLiteral("Easy"),
    7, 7,
    30,
    QStringLiteral("~22 clues (7×7)"),
    QStringLiteral("Relaxed 7×7 grid, accessible deductions")
};

static const Difficulty s_medium = {
    QStringLiteral("medium"),
    QStringLiteral("Medium"),
    10, 10,
    35,
    QStringLiteral("~45 clues (10×10)"),
    QStringLiteral("Balanced 10×10 challenge with intricate patterns")
};

static const Difficulty s_hard = {
    QStringLiteral("hard"),
    QStringLiteral("Hard"),
    15, 15,
    45,
    QStringLiteral("~95 clues (15×15)"),
    QStringLiteral("Expansive 15×15 grid demanding global loop analysis")
};

static const Difficulty s_master = {
    QStringLiteral("master"),
    QStringLiteral("Master"),
    20, 20,
    60,
    QStringLiteral("~160 clues (20×20)"),
    QStringLiteral("Epic 20×20 grid for grandmasters; really hard")
};

static const std::array<Difficulty, 4> s_all = {
    s_easy, s_medium, s_hard, s_master
};

const Difficulty &Difficulty::easy() { return s_easy; }
const Difficulty &Difficulty::medium() { return s_medium; }
const Difficulty &Difficulty::hard() { return s_hard; }
const Difficulty &Difficulty::master() { return s_master; }
const std::array<Difficulty, 4> &Difficulty::all() { return s_all; }

Difficulty Difficulty::fromKey(const QString &key)
{
    const QString k = key.toLower();
    if (k == QStringLiteral("simple") || k == QStringLiteral("easy"))
        return s_easy;
    if (k == QStringLiteral("medium") || k == QStringLiteral("intermediate"))
        return s_medium;
    if (k == QStringLiteral("hard") || k == QStringLiteral("expert"))
        return s_hard;
    if (k == QStringLiteral("master"))
        return s_master;
    return s_easy;
}
