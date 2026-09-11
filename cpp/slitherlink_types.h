#pragma once

#include <cstdint>
#include <vector>
#include <utility>

enum class EdgeState : int8_t {
    Empty = 0,
    Line = 1,
    Cross = 2
};

struct SlitherlinkGrid {
    int rows = 5;
    int cols = 5;

    int numCells() const { return rows * cols; }
    int numVerts() const { return (rows + 1) * (cols + 1); }
    int numHEdges() const { return (rows + 1) * cols; }
    int numVEdges() const { return rows * (cols + 1); }
    int numEdges() const { return numHEdges() + numVEdges(); }

    bool isHEdge(int edgeIdx) const {
        return edgeIdx >= 0 && edgeIdx < numHEdges();
    }

    int hEdge(int r, int c) const {
        return r * cols + c;
    }

    int vEdge(int r, int c) const {
        return numHEdges() + r * (cols + 1) + c;
    }

    // Given edge index, returns {isVertical, row, col}
    struct EdgeCoord {
        bool isVertical;
        int row;
        int col;
    };

    EdgeCoord edgeCoord(int edgeIdx) const {
        if (isHEdge(edgeIdx)) {
            return {false, edgeIdx / cols, edgeIdx % cols};
        } else {
            int v = edgeIdx - numHEdges();
            return {true, v / (cols + 1), v % (cols + 1)};
        }
    }

    // Returns the 4 boundary edges of cell (r, c): top, bottom, left, right
    std::vector<int> cellEdges(int r, int c) const {
        return {
            hEdge(r, c),       // top
            hEdge(r + 1, c),   // bottom
            vEdge(r, c),       // left
            vEdge(r, c + 1)    // right
        };
    }

    // Returns incident edges to vertex (vr, vc)
    std::vector<int> vertEdges(int vr, int vc) const {
        std::vector<int> e;
        if (vc > 0) e.push_back(hEdge(vr, vc - 1));
        if (vc < cols) e.push_back(hEdge(vr, vc));
        if (vr > 0) e.push_back(vEdge(vr - 1, vc));
        if (vr < rows) e.push_back(vEdge(vr, vc));
        return e;
    }

    // Returns the 2 vertex indices connected by edgeIdx
    std::pair<int, int> edgeEndpoints(int edgeIdx) const {
        if (isHEdge(edgeIdx)) {
            int r = edgeIdx / cols;
            int c = edgeIdx % cols;
            return { r * (cols + 1) + c, r * (cols + 1) + (c + 1) };
        } else {
            int v = edgeIdx - numHEdges();
            int r = v / (cols + 1);
            int c = v % (cols + 1);
            return { r * (cols + 1) + c, (r + 1) * (cols + 1) + c };
        }
    }

    // Returns up to 2 cell indices (r * cols + c) adjacent to edgeIdx
    std::vector<int> adjacentCells(int edgeIdx) const {
        std::vector<int> cells;
        if (isHEdge(edgeIdx)) {
            int r = edgeIdx / cols;
            int c = edgeIdx % cols;
            if (r > 0) cells.push_back((r - 1) * cols + c);
            if (r < rows) cells.push_back(r * cols + c);
        } else {
            int v = edgeIdx - numHEdges();
            int r = v / (cols + 1);
            int c = v % (cols + 1);
            if (c > 0) cells.push_back(r * cols + (c - 1));
            if (c < cols) cells.push_back(r * cols + c);
        }
        return cells;
    }
};
