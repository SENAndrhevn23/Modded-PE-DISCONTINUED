#ifndef _H_HEAD1_
#define _H_HEAD1_
    /**
     * Returns the peak (maximum so far) resident set size (physical
     * memory use) measured in bytes, or zero if the value cannot be
     * determined on this OS.
     */
    extern size_t getPeakRSS();

    /**
     * Returns the current resident set size (physical memory use) measured
     * in bytes, or zero if the value cannot be determined on this OS.
     */
    extern size_t getCurrentRSS();
#endif