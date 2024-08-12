#include "nws.hh"

#include <fstream> 
#include <iostream> 
#include <ostream>
#include <string> 

using namespace sycl;

struct tile {
  int i;
  int j;

  int xsize;
  int ysize;
};

// Scores
const int MATCH_SCORE = 1;
const int MISMATCH_SCORE = -1;
const int GAP_PENALTY = -2;

/**
 * @brief helper function to sort the tiled matrix by its position
 */
bool compare(tile a, tile b) { return (a.i + a.j) > (b.i + b.j); }

/**
 * @brief Tile the n x m matrix into tile_size large parts
 * 
 * @param n the length of sequence 1
 * @param m the length of sequence 2
 * @param tile_size how large is each side of the tile supposed to be
 * @return std::vector<tile>  the tiled matrix
 */
std::vector<tile> get_tiled_matrix(std::string seq1, std::string seq2, int tile_size) {
  std::vector<tile> matrix;
  int n = seq1.size();
  int m = seq2.size();

  for (int i = 0; i <= n; i += tile_size) {
    for (int j = 0; j <= m; j += tile_size) {

      tile t;
      t.i = i;
      t.j = j;


      t.xsize = std::min(tile_size, (int(n) + 1) - i);
      t.ysize = std::min(tile_size, (int(m) + 1) - j);

      matrix.push_back(t);
    }
  }
  
  sort(matrix.begin(), matrix.end(), compare);
  return matrix;
}

int main(int argc, char *argv[]) {
  // Select the device sycl is supposed to use
  // try gpu first and cpu if not applicable
  sycl::device d;
  try {
    d = sycl::device(sycl::gpu_selector_v);
  } catch (sycl::exception const &e) {
    std::cout << "Cannot select a GPU\n" << e.what() << "\n";
    std::cout << "Using a CPU device\n";
    d = sycl::device(sycl::cpu_selector_v);
  }


  std::string seq1, seq2, line;

  int tile_size = atoi(argv[1]);
  int offset = 0;
  if (tile_size == 0) {
    std::cout << "Assuming a tile size of 64x64" << std::endl;
    tile_size = 64;
    offset = 1;
  }

  std::ifstream inputFile(argv[2 - offset]);
  if (!inputFile.is_open()) {
    std::cerr << "Error reading file " << argv[2 - offset] << std::endl;
    return 1;
  }

  if (argc >= 4 - offset) {
    std::ifstream inputFile2(argv[3 - offset]);
    if (!inputFile2.is_open()) {
      std::cerr << "Error reading file " << argv[3 - offset] << std::endl;
      return 1;
    }
    while (getline(inputFile, line)) {
      seq1 += line;
    }
        while (getline(inputFile2, line)) {
      seq2 += line;
    }
  } else {
    while (getline(inputFile, line)) {
      seq1 += line;
      seq2 += line;
    }
  }

  size_t n = seq1.size() + 1;
  size_t m = seq2.size() + 1;


  std::vector<tile> M = get_tiled_matrix(seq1, seq2, tile_size);

  sycl::queue q;

  sycl::buffer<int, 1> results(sycl::range<1>(n*m));

  // Setup subsets (rows in rotated matrix)
  for (int i = 0; i < std::ceil((n + m) / tile_size) + 1; i++) {
    std::vector<tile> subset;
    int counter = (M.back().i + M.back().j);

    // Split the matrix into lines, so called subsets
    do {
      if (M.empty()) {
        break;
      }
      subset.push_back(M.back());
      M.pop_back();
    } while ((M.back().i + M.back().j) == counter);

    if (!subset.empty()) {
      sycl::buffer<char, 1> bSeq1(seq1.data(), sycl::range<1>{seq1.size()});
      sycl::buffer<char, 1> bSeq2(seq2.data(), sycl::range<1>{seq2.size()});
      sycl::buffer<tile, 1> bSubset(subset.data(),
                                   sycl::range<1>{subset.size()});


      // This is the part that actually does the calculations
      q.submit([&](sycl::handler &cgh) {
        // create accessors for the buffers we defined earlier
        auto aSubset = sycl::accessor{bSubset, cgh, sycl::read_only};
        auto aResult = sycl::accessor{results, cgh, sycl::read_write};
        auto aSeq1 = sycl::accessor{bSeq1, cgh, sycl::read_only};
        auto aSeq2 = sycl::accessor{bSeq2, cgh, sycl::read_only};

        sycl::stream os(1024, 128, cgh);
        // parallel version of the for loop in sycl
        cgh.parallel_for(sycl::range<1>(aSubset.size()), [=](sycl::id<1> idx) {
          for (int x = 0; x < aSubset[idx].xsize; x++) {
            for (int y = 0; y < aSubset[idx].ysize; y++) {
              int posx = aSubset[idx].i + x;
              int posy = aSubset[idx].j + y;

              if (posx > 0 && posy > 0) {
                char char1 = aSeq1[posx-1];
                char char2 = aSeq2[posy-1];
                int sub = aResult[(posx - 1) * m + posy - 1] +
                        (char1 == char2 ? MATCH_SCORE
                                                          : MISMATCH_SCORE);
                int del = aResult[(posx - 1) * m + posy] + GAP_PENALTY;
                int ins = aResult[posx * m + posy - 1] + GAP_PENALTY;
                int result = std::max({sub, del, ins});
                aResult[posx * m + posy] = result;
              } else if (posx > 0) {
                aResult[posx * m + posy] = aResult[(posx - 1) * m + posy] + GAP_PENALTY;
              } else if (posy > 0) {
                aResult[posx * m + posy] = aResult[posx * m + posy - 1] + GAP_PENALTY;
              } else {
                aResult[posx * m + posy] = 0;
              }
            }
          }
        });
      });
      q.wait();
    }
  }

  // std::cout << std::endl;
  // std::cout << std::endl;
  sycl::host_accessor result{results};
  // for (int i = 0; i < n; i++) {
  //   for (int j = 0; j < m; j++) {
  //     std::cout << result[i * m + j] << " ";
  //   }
  //   std::cout << std::endl;
  // }
  std::cout << result[(n-1) * m + (m-1)];

}
