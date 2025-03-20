#include <iostream>
#include <fstream>
#include <cmath>
#include <vector>
#include <algorithm>
#include <cassert>
using namespace std;

string reference_list[35000];
string hit_or_miss[35000];

int main(int argc, char *argv[]) {
    /* Check for correct number of command-line arguments */
    if (argc != 4) {
        cout << "Please Input: project cache1.org reference1.lst index.rpt" << endl;
        return 0;
    }

    /* Extract filenames from command-line arguments */
    string config_file_name = argv[1];
    string input_file_name = argv[2];
    string output_file_name = argv[3];
    fstream file;

    /********************* cache1.org **************************/
    /* Open the cache configuration file */
    file.open(config_file_name, ios::in);
    if (!file) {
        cerr << "Cannot Open File: " << config_file_name << endl;
        exit(1);
    }

    /* Read cache configuration values */
    string header;
    int data;
    int data_num = 0;
    int data_list[4] = {0};
    while(file >> header >> data) {
        data_list[data_num++] = data;
    }
    file.close();

    /* Assign cache configuration values */
    int address_bits = data_list[0];
    int block_size = data_list[1];
    int cache_sets = data_list[2];
    int associativity = data_list[3];

    /* Calculate offset, index, and tag bit counts */
    int offset_bit_count = log2(block_size);
    int index_bit_count = log2(cache_sets);
    int index_bit[128] = {0};
    int tag_bit_count = address_bits - index_bit_count - offset_bit_count;

    /* Determine the index bits based on offset */
    for(int i = offset_bit_count, j = 0; j < index_bit_count; ++i, ++j){
         index_bit[j] = i;
    }

    /********************* reference1.lst **************************/
    /* Open the memory reference file */
    file.open(input_file_name, ios::in);
    if (!file) {
        cerr << "Cannot Open File: " << input_file_name << endl;
        exit(1);
    }

    /* Read memory references into reference_list */
    int ref_num = 0;
    bool already_cout_header = false;
    while(file >> header) {
        reference_list[ref_num] = header;
        if(!already_cout_header){
            file >> header;
            reference_list[ref_num] += " " + header;
            already_cout_header = true;
        }
        ++ref_num;
    }
    file.close();

    /********************* Q_i, C_i,j **************************/
    /* Initialize variables for calculating Q and C matrices */
    int address_length = address_bits;
    vector<int> Z(address_length - offset_bit_count,0), O(address_length - offset_bit_count,0);
    vector<vector<int>> E_count(address_length - offset_bit_count, vector<int>(address_length - offset_bit_count,0));
    vector<vector<int>> D_count(address_length - offset_bit_count, vector<int>(address_length - offset_bit_count,0));

    /* Compute Z, O, E_count, and D_count */
    for (int r = 0; r < ref_num; ++r) {
        const string &ref = reference_list[r];
        for(int i = 0; i < address_length - offset_bit_count; ++i) {
            ref[i] == '0' ? Z[i]++ : O[i]++;
        }

        for(int i = 0; i < address_length - offset_bit_count; ++i) {
            for(int j = 0; j < address_length - offset_bit_count; ++j) {
                if (i == j) continue; // skip the same index
                if(ref[i] == ref[j]) {
                    E_count[i][j]++;
                } else {
                    D_count[i][j]++;
                }
            }
        }
    }

    /* Q values */
    vector<double> Q(address_length - offset_bit_count,0.0);
    for(int i = 0; i < address_length - offset_bit_count; ++i) {
        int zi = Z[i];
        int oi = O[i];
        int ma = (zi > oi) ? zi : oi;
        int mi = (zi < oi) ? zi : oi;
        if (ma == 0){
            Q[i] = 0.0;
        }else{
            Q[i] = static_cast<double>(mi) / static_cast<double>(ma);
        }
    }

    /* C values */
    vector<vector<double>> C_val(address_length - offset_bit_count, vector<double>(address_length - offset_bit_count,0.0));
    for(int i = 0; i < address_length - offset_bit_count; ++i) {
        for(int j = i+1; j < address_length - offset_bit_count; ++j) {
            int e = E_count[i][j];
            int d = D_count[i][j];
            int ma = (e > d) ? e : d;
            int mi = (e < d) ? e : d;
            double val;
            if (ma == 0){
                val = 0.0;
            } else{
                val = static_cast<double>(mi) / static_cast<double>(ma);
            }
            C_val[i][j] = val;
            C_val[j][i] = val;
        }
    }

    /* Q and C  */
    int M = address_length - offset_bit_count;
    vector<bool> selected(M,false);
    vector<double> Q_temp = Q;
    vector<int> selected_order;
    selected_order.reserve(M);

    for (int round = 0; round < M; ++round) {
        int best = -1;
        double bestQ = -1.0;
        for (int i = 0; i < M; ++i) {
            if(!selected[i] && Q_temp[i] > bestQ) {
                bestQ = Q_temp[i];
                best = i;
            }
        }

        selected[best] = true;
        selected_order.push_back(best);

        for(int j = 0; j < M; ++j) {
            if(!selected[j]) {
                Q_temp[j] *= C_val[best][j];
            }
        }
    }

    /* Select the final index bits */
    vector<int> chosen_index_bits(selected_order.begin(), selected_order.begin() + index_bit_count);
    /* sort(chosen_index_bits.begin(), chosen_index_bits.end(), greater<int>());*/    

    /********************* clock replacement cache simulation **************************/
    /* Initialize cache data structures */
    int miss_count = 0;
    string cache[cache_sets][associativity];
    bool reference_bit[cache_sets][associativity];
    int clock_pointer[cache_sets];

    for(int i = 0; i < cache_sets; ++i) {
        clock_pointer[i] = 0;
        for(int j = 0; j < associativity; ++j) {
            cache[i][j].clear();
            reference_bit[i][j] = false;
        }
    }

    /* Simulate cache */
    for(int i = 1; i < ref_num - 1; ++i) {
        const string &ref = reference_list[i];

        /* cache index value */
        int idx_val = 0;
        for (int b : chosen_index_bits) {
            idx_val = (idx_val << 1) | (ref[b] - '0');
        }

        /* Extract the tag */
        string tag;
        for (int t = 0; t < address_length - offset_bit_count; ++t) {
            if (t >= address_bits - offset_bit_count || 
                find(chosen_index_bits.begin(), chosen_index_bits.end(), t) != chosen_index_bits.end()) {
                continue;
            }
            tag += ref[t];
        }

        /* Check for cache hit */
        bool hit = false;
        for (int a = 0; a < associativity; ++a) {
            if (cache[idx_val][a] == tag) {
                hit_or_miss[i] = " hit";
                reference_bit[idx_val][a] = true;
                hit = true;
                break;
            }
        }

        if(hit) continue;

        /* Cache miss */
        hit_or_miss[i] = " miss";
        miss_count++;

        int victim = -1;
        for (int tries = 0; tries < associativity; ++tries) {
            int current = clock_pointer[idx_val];
            if (!reference_bit[idx_val][current]) {
                victim = current;
                break;
            }
            reference_bit[idx_val][current] = false;
            clock_pointer[idx_val] = (clock_pointer[idx_val] + 1) % associativity;
        }

        if (victim == -1) {
            victim = clock_pointer[idx_val];
        }

        /* Replace data*/
        cache[idx_val][victim] = tag;
        reference_bit[idx_val][victim] = true;
        clock_pointer[idx_val] = (victim + 1) % associativity;
    }

    /********************* index.rpt **************************/
    /* Write results to output file */
    file.open(output_file_name, ios::out);
    if(!file) {
        cerr << "Cannot Open File: " << output_file_name << endl;
        exit(1);
    }

    file << "Address bits: " << address_bits << endl;
    file << "Block size: " << block_size << endl;
    file << "Cache sets: " << cache_sets << endl;
    file << "Associativity: " << associativity << endl;
    file << endl;
    file << "Offset bit count: " << offset_bit_count << endl;
    file << "Indexing bit count: " << index_bit_count << endl;
    file << "Indexing bits:";
    for (int i = index_bit_count - 1; i >= 0; --i) {
        int left_bit = chosen_index_bits[i];
        int right_bit = (address_bits - 1) - left_bit; /* convert index ( 0 from left ) to from right */
        file << " " << right_bit;
    }
    file << endl << endl;

    for(int i = 0; i < ref_num; ++i){
        file << reference_list[i] << hit_or_miss[i] << endl;
    }
    file << endl;

    file << "Total cache miss count: " << miss_count << endl;
    file.close();
    return 0;
}