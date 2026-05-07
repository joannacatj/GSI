#ifndef ISOMORPHISM_H
#define ISOMORPHISM_H

#include "../graph/Graph.h"
#include "../match/Match.h"
#include <unordered_map>
#include <vector>
#include <utility>

// Forward declarations
class Graph;

std::vector<std::unordered_map<int, int>> findIsomorphisms(Graph* query, Graph* data, bool find_first=false);
void printMapping(const std::unordered_map<int, int>& mapping);

void initializeGPU(int dev, bool verbose);

// Declare the function to create a graph from data
Graph* createGraph(const std::vector<int>& nodeIDs, const std::vector<int>& nodeLabels, 
                  const std::vector<std::pair<int, int>>& edgeIDs, const std::vector<int>& edgeLabels, 
                  bool column_oriented);

#endif // ISOMORPHISM_H
