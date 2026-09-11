#pragma once

#include <QString>
#include <array>

struct Difficulty {
    QString key;
    QString label;
    int rows = 7;
    int cols = 7;
    int factor = 28;
    QString clueHint;
    QString desc;

    static const Difficulty &easy();
    static const Difficulty &medium();
    static const Difficulty &hard();
    static const Difficulty &master();
    static const std::array<Difficulty, 4> &all();
    static Difficulty fromKey(const QString &key);
};
