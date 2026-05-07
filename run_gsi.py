#!/usr/bin/env python3
import argparse
import time

import networkx as nx

import GSI


def read_graph(path):
    graph = nx.DiGraph()
    with open(path, "r", encoding="utf-8") as fp:
        lines = [line.strip() for line in fp if line.strip()]

    if not lines:
        raise ValueError(f"empty graph file: {path}")

    header = lines[0].split()
    if header[0] != "t":
        raise ValueError(f"expected graph header starting with 't' in {path}")

    if len(header) >= 3 and header[1] == "#":
        if int(header[2]) == -1:
            raise ValueError(f"end-of-file graph marker is not a graph: {path}")
        if len(lines) < 2:
            raise ValueError(f"missing legacy graph size line: {path}")
        for line in lines[2:]:
            cols = line.split()
            if cols[0] == "t":
                break
            if cols[0] == "v":
                graph.add_node(int(cols[1]), label=int(cols[2]))
            elif cols[0] == "e":
                graph.add_edge(int(cols[1]), int(cols[2]), label=int(cols[3]))
        return graph

    if len(header) < 3:
        raise ValueError(f"expected text graph header 't N M' in {path}")

    expected_vertices = int(header[1])
    expected_edges = int(header[2])
    for line in lines[1:]:
        cols = line.split()
        if cols[0] == "t":
            break
        if cols[0] == "v":
            graph.add_node(int(cols[1]), label=int(cols[2]), degree=int(cols[3]))
        elif cols[0] == "e":
            graph.add_edge(int(cols[1]), int(cols[2]), label=1)

    if graph.number_of_nodes() != expected_vertices:
        print(f"warning: {path} header has {expected_vertices} vertices, parsed {graph.number_of_nodes()}")
    if graph.number_of_edges() != expected_edges:
        print(f"warning: {path} header has {expected_edges} edges, parsed {graph.number_of_edges()}")

    return graph


def main():
    parser = argparse.ArgumentParser(description="Run GSI subgraph matching from Python.")
    parser.add_argument("data_graph", help="Path to the data graph")
    parser.add_argument("query_graph", help="Path to the query graph")
    parser.add_argument("--find-first", action="store_true", help="Stop after the first complete match")
    parser.add_argument("--device", type=int, default=0, help="CUDA device id")
    parser.add_argument("--bidirectional", action="store_true", help="Add reverse edges when converting to GSI graphs")
    parser.add_argument("--print-limit", type=int, default=0, help="Print up to this many mappings")
    args = parser.parse_args()

    total_start = time.perf_counter()
    load_start = time.perf_counter()
    data_nx = read_graph(args.data_graph)
    query_nx = read_graph(args.query_graph)
    load_end = time.perf_counter()

    print(f"data graph: |V|={data_nx.number_of_nodes()} |E|={data_nx.number_of_edges()}")
    print(f"query graph: |V|={query_nx.number_of_nodes()} |E|={query_nx.number_of_edges()}")

    GSI.initGPU(args.device)
    data_gsi, data_id_map = GSI.nxGraph(data_nx, bidirectional=args.bidirectional, column_oriented=True)
    query_gsi, query_id_map = GSI.nxGraph(query_nx, bidirectional=args.bidirectional, column_oriented=False)

    match_start = time.perf_counter()
    found, mappings = GSI.findIsomorphism(query_gsi, data_gsi, find_first=args.find_first)
    match_end = time.perf_counter()

    print(f"found: {int(found)}")
    print(f"num_mappings: {len(mappings)}")
    if args.find_first:
        print("find_first: 1")
        print(f"found_first: {int(GSI.getLastFoundFirst())}")
        print(f"fms: {GSI.getLastFMS()}")

    for index, mapping in enumerate(mappings[:args.print_limit], start=1):
        readable = {
            query_id_map[query_internal]: data_id_map[data_internal]
            for query_internal, data_internal in mapping.items()
        }
        print(f"mapping #{index}: {readable}")

    total_end = time.perf_counter()
    print(f"load_time_ms: {(load_end - load_start) * 1000:.3f}")
    print(f"match_time_ms: {(match_end - match_start) * 1000:.3f}")
    print(f"total_time_ms: {(total_end - total_start) * 1000:.3f}")


if __name__ == "__main__":
    main()
