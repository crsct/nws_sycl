#include "nws.hh"

using namespace cl;

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
std::vector<tile> get_tiled_matrix(int n, int m, int tile_size) {
  std::vector<tile> matrix;
  for (int i = 1; i <= n; i += tile_size) {
    for (int j = 1; j <= m; j += tile_size) {
      tile t;
      t.i = i;
      t.j = j;

      if (i <= n - tile_size) {
        t.xsize = tile_size;
      } else {
        t.xsize = (n - i) % tile_size;
      }

      if (j <= m - tile_size) {
        t.ysize = tile_size;
      } else {
        t.ysize = (m - j) % tile_size;
      }

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

  std::cout << "Using " << d.get_info<sycl::info::device::name>();
  std::cout << std::endl << std::endl;

  // first two arguments are read as sequences
  std::string seq1 = argv[1];
  std::string seq2 = argv[2];
  int tile_size = 3;

  size_t n = seq1.size() + 1;
  size_t m = seq2.size() + 1;

  std::vector<tile> M = get_tiled_matrix(n, m, tile_size);

  sycl::queue q;

  std::vector<int> result(n * m);
  sycl::buffer result_buffer(result.data(), sycl::range<2>{n, m});


  // Initialize the first row and column of the matrix statically
  for (int i = 0; i < n; i++) {
    result[i * m] = i * GAP_PENALTY;
  }

  for (int j = 0; j < m; j++) {
    result[j] = j * GAP_PENALTY;
  }

  // Setup subsets (rows in rotated matrix)
  for (int i = 0; i < floor((n + m) / 3); i++) {
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
      sycl::buffer<tile, 1> buffer(subset.data(),
                                   sycl::range<1>{subset.size()});
      // This is the part that actually does the calculations
      q.submit([&](sycl::handler &cgh) {
        // create accessors for the buffers we defined earlier
        auto aSubset = buffer.get_access<sycl::access::mode::read>(cgh);
        auto aResult = result_buffer.get_access<sycl::access::mode::write>(cgh);

        // parallel version of the for loop in sycl
        cgh.parallel_for(sycl::range<1>(aSubset.size()), [=](sycl::id<1> idx) {
          for (int x = 0; x < aSubset[idx].xsize; x++) {
            for (int y = 0; y < aSubset[idx].ysize; y++) {
              int posx = aSubset[idx].i + x;
              int posy = aSubset[idx].j + y;

              int sub = aResult[posx - 1][posy - 1] +
                        (seq1[posx - 1] == seq2[posy - 1] ? MATCH_SCORE
                                                          : MISMATCH_SCORE);
              int del = aResult[posx - 1][posy] + GAP_PENALTY;
              int ins = aResult[posx][posy - 1] + GAP_PENALTY;
              aResult[posx][posy] = std::max({sub, del, ins});
            }
          }
        });
      });
      q.wait();
    }
  }

  std::cout << "Seq1: " + seq1 << std::endl << "Seq2: " + seq2 << std::endl;
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      std::cout << result[i * m + j] << " ";
    }
    std::cout << std::endl;
  }
}
