#include "difficulty.h"

static const Difficulty s_easy = {
    QStringLiteral("simple"),
    QStringLiteral("Easy"),
    5, 5,
    28,
    QStringLiteral("~12 clues (5×5)"),
    QStringLiteral("Relaxed 5×5 grid, great for quick sessions")
};

static const Difficulty s_medium = {
    QStringLiteral("medium"),
    QStringLiteral("Medium"),
    7, 7,
    56,
    QStringLiteral("~22 clues (7×7)"),
    QStringLiteral("Balanced 7×7 challenge for regular players")
};

static const Difficulty s_hard = {
    QStringLiteral("hard"),
    QStringLiteral("Hard"),
    10, 10,
    112,
    QStringLiteral("~45 clues (10×10)"),
    QStringLiteral("10×10 grid with intricate deduction patterns")
};

static const Difficulty s_master = {
    QStringLiteral("master"),
    QStringLiteral("Master"),
    15, 15,
    156,
    QStringLiteral("~90 clues (15×15)"),
    QStringLiteral("Expansive 15×15 puzzle for loop masters")
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
