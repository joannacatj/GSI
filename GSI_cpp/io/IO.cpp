/*=============================================================================
# Filename: IO.cpp
# Author: Bookug Lobert 
# Mail: 1181955272@qq.com
# Last Modified: 2016-10-24 22:55
# Description: 
=============================================================================*/

#include "IO.h"

using namespace std;

namespace {
string trim(const string& line)
{
    size_t first = line.find_first_not_of(" \t\r\n");
    if (first == string::npos) {
        return "";
    }
    size_t last = line.find_last_not_of(" \t\r\n");
    return line.substr(first, last - first + 1);
}

bool readNonEmptyLine(FILE* fp, string& line, long* pos = NULL)
{
    char buffer[4096];
    while (true) {
        long current = ftell(fp);
        if (fgets(buffer, sizeof(buffer), fp) == NULL) {
            return false;
        }
        line = trim(buffer);
        if (!line.empty()) {
            if (pos != NULL) {
                *pos = current;
            }
            return true;
        }
    }
}
}

IO::IO()
{
    this->qfp = NULL;
    this->dfp = NULL;
    this->ofp = NULL;
    this->data_id = -1;
}

IO::IO(string query, string data, string file)
{
    this->data_id = -1;
    this->line = "============================================================";
    qfp = fopen(query.c_str(), "r");
    if (qfp == NULL) {
        cerr << "input open error!" << endl;
        return;
    }
    dfp = fopen(data.c_str(), "r");
    if (dfp == NULL) {
        cerr << "input open error!" << endl;
        return;
    }
    ofp = fopen(file.c_str(), "w+");
    if (ofp == NULL) {
        cerr << "output open error!" << endl;
        return;
    }
}

Graph*
IO::input(FILE* fp)
{
    string line;
    long pos;
    bool flag = false;
    bool textFormat = false;
    int maxVertexLabel = 0;
    Graph* ng = NULL;
    vector<bool> textVertexSeen;

    while (readNonEmptyLine(fp, line, &pos)) {
        char c1 = line[0];
        if (c1 == 't') {
            if (flag) {
                if (textFormat && ng != NULL) {
                    ng->vertexLabelNum = maxVertexLabel;
                }
                fseek(fp, pos, SEEK_SET);
                return ng;
            }
            flag = true;

            istringstream iss(line);
            char t;
            string token;
            iss >> t >> token;
            if (token == "#") {
                int id0;
                iss >> id0;
                if (id0 == -1) {
                    return NULL;
                }
                ng = new Graph;

                if (!readNonEmptyLine(fp, line)) {
                    delete ng;
                    return NULL;
                }
                int numVertex, numEdge;
                istringstream header(line);
                header >> numVertex >> numEdge >> ng->vertexLabelNum >> ng->edgeLabelNum;
            } else {
                int numVertex = atoi(token.c_str());
                int numEdge;
                iss >> numEdge;
                (void)numEdge;
                textFormat = true;
                ng = new Graph;
                ng->vertices.resize(numVertex);
                textVertexSeen.assign(numVertex, false);
                ng->edgeLabelNum = 1;
                ng->vertexLabelNum = 0;
            }
        } else if (c1 == 'v') {
            if (ng == NULL) {
                cerr << "ERROR in input() -- vertex before graph header" << endl;
                return NULL;
            }
            int id1, lb, degree = 0;
            istringstream iss(line);
            char v;
            iss >> v >> id1 >> lb;
            if (textFormat) {
                iss >> degree;
                if (id1 < 0 || id1 >= static_cast<int>(ng->vertices.size())) {
                    cerr << "ERROR in input() -- vertex id out of range" << endl;
                    return NULL;
                }
                textVertexSeen[id1] = true;
                ng->vertices[id1] = Vertex(lb, degree);
                maxVertexLabel = max(maxVertexLabel, lb);
            } else {
                //NOTICE: we add 1 to labels for both vertex and edge, to ensure the label is positive!
                //ng->addVertex(lb+1);
                ng->addVertex(lb);
            }
        } else if (c1 == 'e') {
            if (ng == NULL) {
                cerr << "ERROR in input() -- edge before graph header" << endl;
                return NULL;
            }
            int id1, id2, lb = 1;
            istringstream iss(line);
            char e;
            iss >> e >> id1 >> id2;
            if (textFormat) {
                if (id1 < 0 || id2 < 0 || id1 >= static_cast<int>(textVertexSeen.size()) ||
                    id2 >= static_cast<int>(textVertexSeen.size()) || !textVertexSeen[id1] || !textVertexSeen[id2]) {
                    cerr << "ERROR in input() -- edge uses unknown vertex" << endl;
                    return NULL;
                }
            } else {
                iss >> lb;
            }
            //NOTICE:we treat this graph as directed, each edge represents two
            //This may cause too many matchings, if to reduce, only add the first one
            //ng->addEdge(id1, id2, lb+1);
            ng->addEdge(id1, id2, lb);
            //ng->addEdge(id2, id1, lb);
        } else {
            cerr << "ERROR in input() -- invalid char" << endl;
            return NULL;
        }
    }

    if (textFormat && ng != NULL) {
        ng->vertexLabelNum = maxVertexLabel;
    }
    return ng;
}

bool
IO::input(Graph*& data_graph)
{
    data_graph = this->input(this->dfp);
    if (data_graph == NULL)
        return false;
    this->data_id++;
    data_graph->preprocessing(true);
    return true;
}

bool
IO::input(vector<Graph*>& query_list)
{
    Graph* graph = NULL;
    while (true) {
        graph = this->input(qfp);
        if (graph == NULL) //to the end
            break;
        graph->preprocessing(false);
        query_list.push_back(graph);
    }

    return true;
}

bool
IO::output(int qid)
{
    fprintf(ofp, "query graph:%d    data graph:%d\n", qid, this->data_id);
    fprintf(ofp, "%s\n", line.c_str());
    return true;
}

bool
IO::output()
{
    fprintf(ofp, "\n\n\n");
    return true;
}

bool
IO::output(unsigned* final_result, unsigned result_row_num, unsigned result_col_num, int* id_map)
{
    cout << "result: " << result_row_num << " " << result_col_num << endl;
    int i, j, k;
    for (i = 0; i < result_row_num; ++i) {
        unsigned* ans = final_result + i * result_col_num;
        for (j = 0; j < result_col_num; ++j) {
            k = ans[id_map[j]];
            fprintf(ofp, "(%u, %u) ", j, k);
        }
        fprintf(ofp, "\n");
    }
    fprintf(ofp, "\n\n\n");
    return true;
}

bool
IO::output(int* m, int size)
{
    for (int i = 0; i < size; ++i) {
        fprintf(ofp, "(%d, %d) ", i, m[i]);
    }
    fprintf(ofp, "\n");
    return true;
}

void
IO::flush()
{
    fflush(this->ofp);
}

IO::~IO()
{
    fclose(this->qfp);
    this->qfp = NULL;
    fclose(this->dfp);
    this->dfp = NULL;
    fclose(this->ofp);
    this->ofp = NULL;
}
