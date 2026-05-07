#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include "main/isomorphism.h"
#include "graph/Graph.h"
#include "util/Util.h"
#include "io/IO.h"
#include "match/Match.h"

namespace py = pybind11;

/**
 * @brief Python bindings for the C++ classes and functions using pybind11.
 */
PYBIND11_MODULE(isomorphism, m) {
    /**
     * @brief Binds the Graph class to Python.
     */
    py::class_<Graph>(m, "Graph")
        .def(py::init<>())  // Constructor
        .def("add_vertex", &Graph::addVertex, "Add a vertex to the graph with a given label")
        .def("add_edge", &Graph::addEdge, "Add an edge to the graph between two vertices with a given label")
        .def("transform_to_CSR", &Graph::transformToCSR, "Transform the graph to CSR format")
        .def("preprocessing", &Graph::preprocessing, "Preprocess the graph for isomorphism checking")
        .def("build_signature", &Graph::buildSignature, "Build the signature for the graph")
        .def("print_graph", &Graph::printGraph, "Print the graph")
        .def("count_max_degree", &Graph::countMaxDegree, "Count the maximum degree of vertices in the graph")
        .def("vSize", &Graph::vSize, "Get the number of vertices in the graph");

    /**
     * @brief Binds the findIsomorphisms function to Python.
     * 
     * @param query The query graph.
     * @param data The data graph.
     * @return A vector of unordered maps representing the isomorphisms.
     */
    m.def("find_isomorphisms", &findIsomorphisms, "A function that finds isomorphisms between two graphs",
          py::arg("query"), py::arg("data"), py::arg("find_first")=false);

    /**
     * @brief Binds the printMapping function to Python.
     * 
     * @param mapping The mapping of vertices from the query graph to the data graph.
     */
    m.def("print_mapping", &printMapping, "A function that prints the mapping of isomorphisms",
          py::arg("mapping"));

    /**
     * @brief Binds the createGraph function to Python.
     * 
     * @param nodeIDs The IDs of the nodes.
     * @param nodeLabels The labels of the nodes.
     * @param edgeIDs The pairs of node IDs representing edges.
     * @param edgeLabels The labels of the edges.
     * @param flag A boolean flag indicating column-oriented processing.
     * @return A pointer to the created Graph.
     */
    m.def("create_graph", &createGraph, py::arg("nodeIDs"), py::arg("nodeLabels"), 
          py::arg("edgeIDs"), py::arg("edgeLabels"), py::arg("flag"),
          py::return_value_policy::take_ownership);

    /**
     * @brief Binds the initializeGPU function to Python.
     * 
     * @param dev The GPU device ID to initialize.
     * @param verbose If GPU initialization status should be printed to the console.
     */
    m.def("initializeGPU", &initializeGPU, py::arg("dev"), py::arg("verbose"));
    m.def("get_last_fms", &getLastFMS, "Return FMS from the last find-first match");
    m.def("get_last_found_first", &getLastFoundFirst, "Return whether the last find-first match found a result");
    m.def("get_last_find_first_mode", &getLastFindFirstMode, "Return whether the last match used find-first mode");
}