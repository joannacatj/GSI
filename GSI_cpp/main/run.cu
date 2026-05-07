/*=============================================================================
# Filename: run.cpp
# Author: bookug
# Mail: bookug@qq.com
# Last Modified: 2017-12-21 16:47
# Description: 
how to time the program?
https://blog.csdn.net/litdaguang/article/details/50520549
warmup GPU and the timing should be the average of 10 runs
=============================================================================*/

#include "../util/Util.h"
#include "../io/IO.h"
#include "../graph/Graph.h"
#include "../match/Match.h"

using namespace std;

//NOTICE:a pattern occurs in a graph, then support++(not the matching num in a graph), support/N >= minsup
vector<Graph*> query_list;

int
main(int argc, const char * argv[])
{
	int i;

	string output = "ans.txt";
    bool find_first = false;
    vector<string> positional;
    for(int argi = 1; argi < argc; ++argi)
    {
        string arg = argv[argi];
        if(arg == "--find-first")
        {
            find_first = true;
        }
        else
        {
            positional.push_back(arg);
        }
    }
	if(positional.size() < 2 || positional.size() > 4)
	{
		cerr<<"usage: "<<argv[0]<<" <data> <query> [output] [device] [--find-first]"<<endl;
		return -1;
	}
	string data = positional[0];
	string query = positional[1];
	if(positional.size() >= 3)
	{
		output = positional[2];
	}
	int dev = 0;
	if(positional.size() == 4)
	{
		dev = atoi(positional[3].c_str());
	}

	//set the GPU and warmup
	Match::initGPU(dev);

	long t1 = Util::get_cur_time();

	IO io = IO(query, data, output);
	//read query file and keep all queries in memory
	io.input(query_list);
	int qnum = query_list.size();
	
	cerr<<"input ok!"<<endl;
	long t2 = Util::get_cur_time();

	unsigned* final_result = NULL;
	int* id_map= NULL;
	unsigned result_row_num = 0, result_col_num = 0;
	Graph* data_graph = NULL;
	//getchar();
	while(true)
	{
		//cout<<"to input the data graph"<<endl;
		/*getchar();*/
		if(!io.input(data_graph))
		{
			break;
		}
		//cout<<"now to print the data graph"<<endl;
		/*getchar();*/
		//data_graph->printGraph();
		/*getchar();*/
		//NOTICE: we just compare the matching time(include the communication with GPU)
        long start = Util::get_cur_time();
		for(i = 0; i < qnum; ++i)
		{
			Match m(query_list[i], data_graph);
			io.output(i);
		/*getchar();*/
            long query_start = Util::get_cur_time();
			m.match(final_result, result_row_num, result_col_num, id_map, find_first);
            long query_end = Util::get_cur_time();
            cerr<<"query "<<i<<" match used: "<<(query_end-query_start)<<" ms"<<endl;
            if(find_first)
            {
                cerr<<"query "<<i<<" find-first found: "<<(result_row_num > 0 ? "yes" : "no")<<endl;
            }
		/*getchar();*/
			io.output(final_result, result_row_num, result_col_num, id_map);
			io.flush();
			delete[] final_result;
			/*delete[] id_map;*/
		//cudaDeviceSynchronize();
		//NOTICE: if use VF2 dataset(chemical structures), though graphs are small, but the GPU memory will 
		//be occupied very much because it not really released.
		//We can use cudaDeviceReset() to reset the device with process to release memory, but this will introduce 
		//more initialization time.
		cudaDeviceReset();
		}
        long end = Util::get_cur_time();
        cerr<<"match used: "<<(end-start)<<" ms"<<endl;

		delete data_graph;
	}

	cerr<<"match ended!"<<endl;
	long t3 = Util::get_cur_time();

	//output the time for contrast
	cerr<<"part 1 used: "<<(t2-t1)<<"ms"<<endl;
	cerr<<"part 2 used: "<<(t3-t2)<<"ms"<<endl;
	cerr<<"total time used: "<<(t3-t1)<<"ms"<<endl;
	//getchar();

	//release all and flush cached writes
	for(i = 0; i < qnum; ++i)
	{
		delete query_list[i];
	}
	io.flush();
	//getchar();

	return 0;
}