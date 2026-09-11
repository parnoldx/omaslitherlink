#include "generator.h"

#include <algorithm>
#include <chrono>
#include <queue>
#include <random>

namespace {

struct DSU {
    std::vector<int> parent;
    explicit DSU(int n) : parent(n) {
        for (int i = 0; i < n; ++i) parent[i] = i;
    }
    int find(int i) {
        if (parent[i] == i) return i;
        return parent[i] = find(parent[i]);
    }
    bool unite(int i, int j) {
        int rootI = find(i);
        int rootJ = find(j);
        if (rootI != rootJ) {
            parent[rootI] = rootJ;
            return true;
        }
        return false;
    }
};

enum EdgeBranchState : int8_t {
    STATE_UNKNOWN = -1,
    STATE_CROSS = 0,
    STATE_LINE = 1
};

class SolverImpl {
public:
    const SlitherlinkGrid &grid;
    const QVector<int> &clues;
    int solutionCount = 0;
    int steps = 0;
    static constexpr int MAX_STEPS = 3000;
    std::vector<int8_t> solutionEdges;

    SolverImpl(const SlitherlinkGrid &g, const QVector<int> &c)
        : grid(g), clues(c) {}

    bool propagate(std::vector<int8_t> &edges) {
        bool changed = true;
        while (changed) {
            changed = false;

            // 1. Cell clues
            for (int r = 0; r < grid.rows; ++r) {
                for (int c = 0; c < grid.cols; ++c) {
                    const int clue = clues[r * grid.cols + c];
                    if (clue < 0) continue;
                    const auto ce = grid.cellEdges(r, c);
                    int lines = 0, crosses = 0, unk = 0;
                    for (int e : ce) {
                        if (edges[e] == STATE_LINE) ++lines;
                        else if (edges[e] == STATE_CROSS) ++crosses;
                        else ++unk;
                    }
                    if (lines > clue || lines + unk < clue) return false;
                    if (lines == clue && unk > 0) {
                        for (int e : ce) {
                            if (edges[e] == STATE_UNKNOWN) {
                                edges[e] = STATE_CROSS;
                                changed = true;
                            }
                        }
                    } else if (lines + unk == clue && unk > 0) {
                        for (int e : ce) {
                            if (edges[e] == STATE_UNKNOWN) {
                                edges[e] = STATE_LINE;
                                changed = true;
                            }
                        }
                    }
                }
            }

            // 2. Vertex degrees
            for (int vr = 0; vr <= grid.rows; ++vr) {
                for (int vc = 0; vc <= grid.cols; ++vc) {
                    const auto ve = grid.vertEdges(vr, vc);
                    int lines = 0, crosses = 0, unk = 0;
                    for (int e : ve) {
                        if (edges[e] == STATE_LINE) ++lines;
                        else if (edges[e] == STATE_CROSS) ++crosses;
                        else ++unk;
                    }
                    if (lines > 2) return false;
                    if (lines == 1 && unk == 0) return false;
                    if (lines == 2 && unk > 0) {
                        for (int e : ve) {
                            if (edges[e] == STATE_UNKNOWN) {
                                edges[e] = STATE_CROSS;
                                changed = true;
                            }
                        }
                    } else if (lines == 1 && unk == 1) {
                        for (int e : ve) {
                            if (edges[e] == STATE_UNKNOWN) {
                                edges[e] = STATE_LINE;
                                changed = true;
                            }
                        }
                    } else if (lines == 0 && unk == 1) {
                        for (int e : ve) {
                            if (edges[e] == STATE_UNKNOWN) {
                                edges[e] = STATE_CROSS;
                                changed = true;
                            }
                        }
                    }
                }
            }
        }
        return true;
    }

    bool hasPrematureSubloop(const std::vector<int8_t> &edges) {
        DSU dsu(grid.numVerts());
        std::vector<int> vertDegrees(grid.numVerts(), 0);
        int cycleCount = 0;

        for (int e = 0; e < grid.numEdges(); ++e) {
            if (edges[e] == STATE_LINE) {
                auto [u, v] = grid.edgeEndpoints(e);
                ++vertDegrees[u];
                ++vertDegrees[v];
                if (!dsu.unite(u, v)) {
                    ++cycleCount;
                }
            }
        }

        if (cycleCount > 0) {
            int root = -1;
            for (int v = 0; v < grid.numVerts(); ++v) {
                if (vertDegrees[v] > 0) {
                    if (root == -1) root = dsu.find(v);
                    else if (dsu.find(v) != root) {
                        return true;
                    }
                }
            }
            bool allDegree2 = true;
            for (int v = 0; v < grid.numVerts(); ++v) {
                if (vertDegrees[v] > 0 && vertDegrees[v] != 2) {
                    allDegree2 = false;
                    break;
                }
            }
            if (allDegree2) {
                for (int r = 0; r < grid.rows; ++r) {
                    for (int c = 0; c < grid.cols; ++c) {
                        const int clue = clues[r * grid.cols + c];
                        if (clue >= 0) {
                            int lines = 0;
                            for (int e : grid.cellEdges(r, c)) {
                                if (edges[e] == STATE_LINE) ++lines;
                            }
                            if (lines != clue) return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    bool isCompleteLoop(const std::vector<int8_t> &edges) {
        int totalLines = 0;
        for (int8_t s : edges) {
            if (s == STATE_LINE) ++totalLines;
        }
        if (totalLines < 4) return false;

        DSU dsu(grid.numVerts());
        std::vector<int> vertDegrees(grid.numVerts(), 0);
        int firstVert = -1;

        for (int e = 0; e < grid.numEdges(); ++e) {
            if (edges[e] == STATE_LINE) {
                auto [u, v] = grid.edgeEndpoints(e);
                ++vertDegrees[u];
                ++vertDegrees[v];
                dsu.unite(u, v);
                if (firstVert == -1) firstVert = u;
            }
        }

        for (int v = 0; v < grid.numVerts(); ++v) {
            if (vertDegrees[v] != 0 && vertDegrees[v] != 2) return false;
            if (vertDegrees[v] == 2 && dsu.find(v) != dsu.find(firstVert)) {
                return false;
            }
        }

        for (int r = 0; r < grid.rows; ++r) {
            for (int c = 0; c < grid.cols; ++c) {
                const int clue = clues[r * grid.cols + c];
                if (clue >= 0) {
                    int lines = 0;
                    for (int e : grid.cellEdges(r, c)) {
                        if (edges[e] == STATE_LINE) ++lines;
                    }
                    if (lines != clue) return false;
                }
            }
        }

        return true;
    }

    void solve(std::vector<int8_t> edges, int limit) {
        if (solutionCount >= limit) return;
        if (++steps > MAX_STEPS) {
            solutionCount = 99; // Indicate unbounded/ambiguous branch
            return;
        }
        if (!propagate(edges)) return;
        if (hasPrematureSubloop(edges)) return;

        int bestEdge = -1;
        int maxPriority = -1;

        for (int e = 0; e < grid.numEdges(); ++e) {
            if (edges[e] == STATE_UNKNOWN) {
                auto [u, v] = grid.edgeEndpoints(e);
                int prio = 0;
                for (int ne : grid.vertEdges(u / (grid.cols + 1), u % (grid.cols + 1))) {
                    if (edges[ne] == STATE_LINE) prio += 2;
                }
                for (int ne : grid.vertEdges(v / (grid.cols + 1), v % (grid.cols + 1))) {
                    if (edges[ne] == STATE_LINE) prio += 2;
                }
                if (prio > maxPriority) {
                    maxPriority = prio;
                    bestEdge = e;
                }
            }
        }

        if (bestEdge == -1) {
            if (isCompleteLoop(edges)) {
                ++solutionCount;
                if (solutionCount == 1) {
                    solutionEdges = edges;
                }
            }
            return;
        }

        edges[bestEdge] = STATE_LINE;
        solve(edges, limit);
        if (solutionCount >= limit) return;

        edges[bestEdge] = STATE_CROSS;
        solve(edges, limit);
    }
};

bool isValidLoopInterior(int R, int C, const std::vector<bool> &inS) {
    auto inBounds = [&](int r, int c) { return r >= 0 && r < R && c >= 0 && c < C; };
    auto idx = [&](int r, int c) { return r * C + c; };

    // Check no diagonal touches in any 2x2:
    for (int r = 0; r < R - 1; ++r) {
        for (int c = 0; c < C - 1; ++c) {
            bool tl = inS[idx(r, c)];
            bool tr = inS[idx(r, c + 1)];
            bool bl = inS[idx(r + 1, c)];
            bool br = inS[idx(r + 1, c + 1)];
            if (tl == br && tr == bl && tl != tr) {
                return false;
            }
        }
    }

    // Check complement is connected to exterior
    std::vector<bool> visitedComp(R * C, false);
    std::queue<std::pair<int, int>> q;
    for (int r = 0; r < R; ++r) {
        for (int c = 0; c < C; ++c) {
            if (!inS[idx(r, c)]) {
                if (r == 0 || r == R - 1 || c == 0 || c == C - 1) {
                    visitedComp[idx(r, c)] = true;
                    q.push({r, c});
                }
            }
        }
    }

    int compVisitedCount = 0;
    while (!q.empty()) {
        auto [cr, cc] = q.front();
        q.pop();
        ++compVisitedCount;
        int dr[] = {-1, 1, 0, 0};
        int dc[] = {0, 0, -1, 1};
        for (int d = 0; d < 4; ++d) {
            int nr = cr + dr[d], nc = cc + dc[d];
            if (inBounds(nr, nc) && !inS[idx(nr, nc)] && !visitedComp[idx(nr, nc)]) {
                visitedComp[idx(nr, nc)] = true;
                q.push({nr, nc});
            }
        }
    }

    int totalNotInS = 0;
    for (int i = 0; i < R * C; ++i) {
        if (!inS[i]) ++totalNotInS;
    }

    return compVisitedCount == totalNotInS;
}

} // namespace

int SlitherlinkEngine::solveCount(const SlitherlinkGrid &grid, const QVector<int> &clues, int limit, QVector<int> *outSolution)
{
    SolverImpl solver(grid, clues);
    std::vector<int8_t> edges(grid.numEdges(), STATE_UNKNOWN);
    solver.solve(edges, limit);
    if (outSolution && solver.solutionCount > 0) {
        outSolution->resize(grid.numEdges());
        for (int i = 0; i < grid.numEdges(); ++i) {
            (*outSolution)[i] = (solver.solutionEdges[i] == STATE_LINE) ? 1 : 0;
        }
    }
    return solver.solutionCount;
}

bool SlitherlinkEngine::isWinState(const SlitherlinkGrid &grid, const QVector<int> &clues, const QVector<int> &edges)
{
    int totalLines = 0;
    for (int v : edges) {
        if (v == 1) ++totalLines;
    }
    if (totalLines < 4) return false;

    DSU dsu(grid.numVerts());
    std::vector<int> vertDegrees(grid.numVerts(), 0);
    int firstVert = -1;

    for (int e = 0; e < grid.numEdges(); ++e) {
        if (edges[e] == 1) {
            auto [u, v] = grid.edgeEndpoints(e);
            ++vertDegrees[u];
            ++vertDegrees[v];
            dsu.unite(u, v);
            if (firstVert == -1) firstVert = u;
        }
    }

    for (int v = 0; v < grid.numVerts(); ++v) {
        if (vertDegrees[v] != 0 && vertDegrees[v] != 2) return false;
        if (vertDegrees[v] == 2 && dsu.find(v) != dsu.find(firstVert)) {
            return false;
        }
    }

    for (int r = 0; r < grid.rows; ++r) {
        for (int c = 0; c < grid.cols; ++c) {
            const int clue = clues[r * grid.cols + c];
            if (clue >= 0) {
                int lines = 0;
                for (int e : grid.cellEdges(r, c)) {
                    if (edges[e] == 1) ++lines;
                }
                if (lines != clue) return false;
            }
        }
    }

    return true;
}

SlitherlinkPuzzle SlitherlinkEngine::generatePuzzle(const Difficulty &difficulty, unsigned int seed)
{
    const int R = difficulty.rows;
    const int C = difficulty.cols;
    SlitherlinkGrid grid{R, C};

    if (seed == 0) {
        seed = static_cast<unsigned int>(std::chrono::system_clock::now().time_since_epoch().count());
    }
    std::mt19937 rng(seed);

    // 1. Generate loop interior
    std::vector<bool> inS(R * C, false);
    inS[(R / 2) * C + (C / 2)] = true;
    int sCount = 1;
    const int target = qMax(4, (R * C) * 45 / 100);

    for (int step = 0; step < 2000 && sCount < target; ++step) {
        std::vector<int> candidates;
        for (int r = 0; r < R; ++r) {
            for (int c = 0; c < C; ++c) {
                if (!inS[r * C + c]) {
                    bool adj = (r > 0 && inS[(r - 1) * C + c]) ||
                               (r < R - 1 && inS[(r + 1) * C + c]) ||
                               (c > 0 && inS[r * C + (c - 1)]) ||
                               (c < C - 1 && inS[r * C + (c + 1)]);
                    if (adj) candidates.push_back(r * C + c);
                }
            }
        }
        if (candidates.empty()) break;
        std::shuffle(candidates.begin(), candidates.end(), rng);
        for (int cand : candidates) {
            inS[cand] = true;
            if (isValidLoopInterior(R, C, inS)) {
                ++sCount;
                break;
            } else {
                inS[cand] = false;
            }
        }
    }

    // Extract loop solution
    QVector<int> solution(grid.numEdges(), 0);
    for (int r = 0; r <= R; ++r) {
        for (int c = 0; c < C; ++c) {
            bool above = (r > 0) ? inS[(r - 1) * C + c] : false;
            bool below = (r < R) ? inS[r * C + c] : false;
            if (above != below) solution[grid.hEdge(r, c)] = 1;
        }
    }
    for (int r = 0; r < R; ++r) {
        for (int c = 0; c <= C; ++c) {
            bool left = (c > 0) ? inS[r * C + (c - 1)] : false;
            bool right = (c < C) ? inS[r * C + c] : false;
            if (left != right) solution[grid.vEdge(r, c)] = 1;
        }
    }

    // Extract complete clues
    QVector<int> clues(R * C, 0);
    for (int r = 0; r < R; ++r) {
        for (int c = 0; c < C; ++c) {
            int count = 0;
            for (int e : grid.cellEdges(r, c)) {
                if (solution[e] == 1) ++count;
            }
            clues[r * C + c] = count;
        }
    }

    // 2. Reduce clues while preserving uniqueness
    std::vector<int> clueIndices(R * C);
    for (int i = 0; i < R * C; ++i) clueIndices[i] = i;
    std::shuffle(clueIndices.begin(), clueIndices.end(), rng);

    int currentClues = R * C;
    const int targetClues = qMax(8, (R * C) * 42 / 100);

    for (int idx : clueIndices) {
        if (currentClues <= targetClues) break;
        const int orig = clues[idx];
        clues[idx] = -1;
        if (solveCount(grid, clues, 2) != 1) {
            clues[idx] = orig;
        } else {
            --currentClues;
        }
    }

    SlitherlinkPuzzle puzzle;
    puzzle.rows = R;
    puzzle.cols = C;
    puzzle.clues = clues;
    puzzle.solution = solution;
    return puzzle;
}
