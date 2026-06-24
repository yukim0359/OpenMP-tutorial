#ifndef HIST_COMMON_H
#define HIST_COMMON_H

#include <stdlib.h>

#ifndef SEED
#define SEED 42
#endif

#ifndef NBINS
#define NBINS 16384
#endif

static void fill_data(int *data, long n, int nbins, int skewed) {
    srand(SEED);
    if (skewed) {
        for (long i = 0; i < n; i++) {
            if (rand() % 100 < 90) {
                data[i] = 0;
            } else {
                data[i] = 1 + (int)(rand() % (nbins - 1));
            }
        }
    } else {
        for (long i = 0; i < n; i++) {
            data[i] = (int)(rand() % nbins);
        }
    }
}

#endif
