#include "../graph/Graph.h"
#include "../match/Match.h"
#include "isomorphism.h"
#include <unordered_map>
#include <vector>
#include <utility>


using namespace std;

/**
 * @brief Creates a graph using given node IDs, node labels, edge IDs, and edge labels.
 * 
 * @param nodeIDs Vector of node IDs.
 * @param nodeLabels Vector of node labels corresponding to node IDs.
 * @param edgeIDs Vector of pairs representing edge connections (from, to).
 * @param edgeLabels Vector of edge labels corresponding to edge IDs.
 * @param column_oriented Boolean flag indicating whether the graph should be column-oriented.
 * @return Pointer to the created Graph object.
 */
Graph* createGraph(const std::vector<int>& nodeIDs, const std::vector<int>& nodeLabels, 
                   const std::vector<std::pair<int, int>>& edgeIDs, const std::vector<int>& edgeLabels, 
                   bool column_oriented) {

    Graph* g = new Graph();

    // Add vertices in order of node label's from least to greatest
    for (size_t i = 0; i < nodeIDs.size(); ++i) {
        g->addVertex(nodeLabels[i]); // Add vertex with corresponding label
    }

    // Add edges
    for (size_t i = 0; i < edgeIDs.size(); ++i) {
        int from = edgeIDs[i].first;
        int to = edgeIDs[i].second;
        int label = edgeLabels[i];
        g->addEdge(from, to, label); // Add edge with corresponding label
    }

    // Set vertexLabelNum and edgeLabelNum
    std::set<int> uniqueVertexCount(nodeLabels.begin(), nodeLabels.end());
    std::set<int> uniqueEdgeCount(edgeLabels.begin(), edgeLabels.end());
    g->setVertexLabelNum(uniqueVertexCount.size());
    g->setEdgeLabelNum(uniqueEdgeCount.size());

    g->preprocessing(column_oriented); // Preprocess the graph with the given column_oriented boolean flag
    //g->printGraph(); // Uncomment to print the graph for debugging purposes
    return g;
}

/**
 * @brief Finds all isomorphisms between the query graph and the data graph.
 * 
 * @param query Pointer to the query Graph object.
 * @param data Pointer to the data Graph object.
 * @return Vector of unordered maps, where each map represents a vertex mapping for one isomorphism.
 */
std::vector<std::unordered_map<int, int>> findIsomorphisms(Graph* query, Graph* data, bool find_first) {
    unsigned* final_result = nullptr;
    int* id_map = nullptr;
    unsigned result_row_num = 0, result_col_num = 0;

    Match m(query, data);

    // Perform the matching
    m.match(final_result, result_row_num, result_col_num, id_map, find_first);

    /*
    // Print final_result, result_row_num, result_col_num, and id_map
    std::cout << "Result Row Num: " << result_row_num << std::endl;
    std::cout << "Result Col Num: " << result_col_num << std::endl;

    if (id_map) {
        std::cout << "ID Map: ";
        for (unsigned j = 0; j < result_col_num; ++j) {
            std::cout << id_map[j] << " ";
        }
        std::cout << std::endl;
    }

    if (final_result) {
        std::cout << "Final Result:" << std::endl;
        for (unsigned i = 0; i < result_row_num; ++i) {
            for (unsigned j = 0; j < result_col_num; ++j) {
                std::cout << final_result[i * result_col_num + j] << " ";
            }
            std::cout << std::endl;
        }
    }
    */
    std::vector<std::unordered_map<int, int>> mappings;
    if (final_result) {
        int i, j, k;
        for (i = 0; i < result_row_num; ++i) {
            // Calculate the pointer to the start of the i-th row in the 1D array
            unsigned* ans = final_result + i * result_col_num;

            // Store a mapping as a hashmap
            std::unordered_map<int, int> mapping;

            // Iterate over each column in the current row
            for (j = 0; j < result_col_num; ++j) {
                // Access the element in the j-th column of the current row using the id_map for column index
                k = ans[id_map[j]];
                // Print the column index and the value to the file
                mapping[j] = k;
            }

            mappings.push_back(mapping);
        }
        delete[] final_result;  // Ensure to free the allocated memory
        final_result = nullptr; // Prevent double free
    }
    return mappings;
}

/**
 * @brief Prints the vertex mappings from the query graph to the data graph.
 * 
 * @param mapping Unordered map where keys are query graph vertex IDs and values are data graph vertex IDs.
 */
void printMapping(const unordered_map<int, int>& mapping) {
    if (mapping.empty()) {
        cout << "No isomorphism found." << endl;
    } else {
        //cout << "Mappings found:" << endl;
        for (const auto& pair : mapping) {
            cout << "Query vertex " << pair.first << " -> Data vertex " << pair.second << endl;
        }
        cout << endl;
    }
}

/**
 * @brief Initializes the GPU for processing.
 * 
 * @param dev The GPU device ID to initialize.
 * @param verbose If GPU initialization status should be printed to the console.
 */
void initializeGPU(int dev, bool verbose){
    Match::initGPU(dev,verbose);
}
