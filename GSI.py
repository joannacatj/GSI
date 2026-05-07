# Imports
from GSI_cpp.isomorphism import create_graph, find_isomorphisms, print_mapping, initializeGPU
import networkx as nx

# Initialize GPU
def initGPU(dev=0,verbose=True):
    """
    Initialize the GPU with the specified device number.

    Args:
        dev (int): The GPU device number to initialize. Default is 0.
    """
    initializeGPU(dev,verbose)

# Create graph
def createGraph(node_ids, node_labels, edge_ids, edge_labels, column_oriented):
    """
    Create a custom Graph object using the provided node IDs, node labels, edge IDs, and edge labels.

    Args:
        node_ids (list of int): List of node IDs.
        node_labels (list of int): List of node labels corresponding to node IDs.
        edge_ids (list of tuple): List of tuples representing edge connections (from, to).
        edge_labels (list of int): List of edge labels corresponding to edge IDs.
        column_oriented (bool): Flag indicating whether the graph should be column-oriented.

    Returns:
        Graph: The created custom Graph object.
    """
    return create_graph(node_ids, node_labels, edge_ids, edge_labels, column_oriented)

# Find Isomorphisms
def findIsomorphism(query, data, find_first=False):
    """
    Find isomorphisms between the query graph and the data graph.

    Args:
        query (Graph): The query graph.
        data (Graph): The data graph.
        find_first (bool): Stop after the first complete match is found. Default is False.

    Returns:
        tuple: A tuple containing a boolean indicating if isomorphisms were found and the list of mappings.
    """
    mappings = find_isomorphisms(query, data, find_first)

    if len(mappings) == 0:
        return False, mappings
    else:
        return True, mappings

# Print Mappings
def printMappings(mappings):
    """
    Print the mappings of isomorphisms.

    Args:
        mappings (list of dict): The list of mappings from the query graph to the data graph.
    """
    for mapping, n in zip(mappings, range(len(mappings))):
    	print(f"====== Mapping #{n+1} =====")
    	print_mapping(mapping)

# NetworkX Graph to Isomorphism Graph
def nxGraph(nx_graph, bidirectional = True, column_oriented = False):
    """
    Convert a NetworkX graph to a custom Graph object suitable for isomorphism detection.

    Args:
        nx_graph (networkx.Graph): The NetworkX graph to convert.
        bidirectional (bool): Flag indicating whether edges should be treated as bidirectional. Default is True.
        column_oriented (bool): Flag indicating whether the graph should be column-oriented. Default is False.

    Returns:
        Graph: The created custom Graph object.
    """

    # Extract node IDs and labels
    node_ids = list(nx_graph.nodes())
    node_labels = [nx_graph.nodes[node_id].get('label', 1) for node_id in node_ids]  # Default label to 1 if not provided

    # Extract edge IDs and labels
    edge_ids = list(nx_graph.edges())
    edge_labels = [1 for edge_id in edge_ids]  # Default label to 1

    '''
    print(node_ids)
    print(edge_ids)
    print("OK SO FAR")
	'''

    # Check if bidirectional flag is set
    if bidirectional:
    	# Create bidirectional edges
    	bidirectional_edges = []
    	for from_node, to_node in edge_ids:
    		bidirectional_edges.append((from_node, to_node))
    		bidirectional_edges.append((to_node, from_node))
    	edge_ids = bidirectional_edges
    	edge_labels = [1 for _ in edge_ids]  # Default label to 1 for all edges

    '''
    print("Node ID's: ", node_ids)
    print("Node Label's: ", node_labels)
    print("zipped: ", list(zip(node_labels,node_ids)))

    print("Edge ID's: ", edge_ids)
    print("Edge Label's: ", edge_labels)
    #print("OK SO FAR")
    print()
    '''

    # Sort nodes by their label in increasing order
    _combined = list(zip(node_labels,node_ids))
    _sorted_combined = sorted(_combined)

    # Unzip the sorted combined array back into two arrays
    A_sorted, B_sorted = zip(*_sorted_combined)

    # Convert the tuples back to lists
    node_labels = list(A_sorted)
    node_ids = list(B_sorted)

    index_node_ids = list(range(len(node_ids)))
    algo_map = {inid: nid for nid, inid in zip(node_ids, index_node_ids)}
    
    '''
    print()
    print("Node Label's: ", node_labels)
    print("Node id's: ",node_ids)
    print("Index node ID's: ", index_node_ids)
    print("zipped: ", list(zip(node_labels,index_node_ids)))
    print("Index map: ", algo_map)
    '''

    # Convert node IDs and edge IDs to required format
    edge_ids = [(node_ids.index(from_node), node_ids.index(to_node)) for from_node, to_node in edge_ids]

    # Create the custom Graph object
    return createGraph(index_node_ids, node_labels, edge_ids, edge_labels, column_oriented), algo_map

# Process chemical graphs
def chemGraphProcess(G, label_map):
	# Create a new node property "label"
	# Encode each unique symbol / elemental_type to an integer in "label"

	# Extract the mode ('symbol' or 'elemental_type')
	mode = list(list(G.nodes.data())[0][1].keys())[0]
	
	# Stores the unique elements
	label_list = []
	# Stores the node -> labels mapping
	label_dict = {}

	# For every node
	for node in G.nodes(mode):
		node_index = node[0]
		node_symbol = node[1]

		label_dict[node_index] = label_map.index(node_symbol)+1

	# Set the node attribute
	nx.set_node_attributes(G, label_dict, "label")

	return G

# Print a graph
def printGraph(G):
	return G.print_graph()

# Print networkx graph:
def print_nx_graph(nx_graph):
    """
    Prints the details of a NetworkX graph including the number of nodes, nodes (ID, label),
    number of edges, and edges ((START NODE, END NODE), label).

    Args:
        nx_graph (networkx.Graph): The NetworkX graph to print.
    """
    # Get nodes and their labels
    node_ids = list(nx_graph.nodes())
    node_labels = {node: nx_graph.nodes[node].get('symbol', 1) for node in node_ids}  # Default label to 1 if not provided

    # Get edges and their labels
    edge_ids = list(nx_graph.edges())
    edge_labels = {(u, v): nx_graph.edges[u, v].get('label', 1) for u, v in edge_ids}  # Default label to 1 if not provided

    # Print the number of nodes
    print(f"Graph contains {len(node_ids)} nodes.")

    # Print nodes (ID, label)
    print("Nodes (ID, label):")
    for node_id in node_ids:
        print(f"({node_id}, {node_labels[node_id]})")

    # Print the number of edges
    print(f"Graph contains {len(edge_ids)} edges.")

    # Print edges ((START NODE, END NODE), label)
    print("Edges ((START NODE, END NODE), label):")
    for (start_node, end_node) in edge_ids:
        print(f"(({start_node}, {end_node}), {edge_labels[(start_node, end_node)]})")


# Given the parent graph (Reactant), return a mapping between chemical symbols/labels to a number
# Encode each unique symbol / elemental_type to an integer in "label"
def encodeLabels(G):
	# Extract the mode ('symbol' or 'elemental_type')
	mode = list(list(G.nodes.data())[0][1].keys())[0]


	_tmp = []

	# Iterate through
	for node in list(G.nodes.data()):
		#ID = node[0]
		symbol = node[1][mode]
		_tmp.append(symbol)
	#print("Encoding: ", list(dict.fromkeys(_tmp)))
	return 	list(dict.fromkeys(_tmp))
