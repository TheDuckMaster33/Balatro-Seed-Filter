__kernel void find_valid_strings(__global char *results,
                                 __global int *result_count,
                                 ulong offset) {
    const char charset[] = {
        '1','2','3','4','5','6','7','8','9',
        'A','B','C','D','E','F','G','H','I','J','K',
        'L','M','N','O','P','Q','R','S','T','U','V',
        'W','X','Y','Z'
    };

    const int charset_len = 35;

    ulong gid = get_global_id(0) + offset;
    ulong index = gid;

    // Convert index to base-35 (charset index)
    char str[8];
    int digit_count = 0;
    int letter_count = 0;

    for (int i = 7; i >= 0; --i) {
        int c = index % charset_len;
        index /= charset_len;

        str[i] = charset[c];

        if (c < 9) {
            digit_count++;
        } else {
            letter_count++;
        }
    }

    // Check for 4 letters and 4 digits
    if (digit_count == 4 && letter_count == 4) {
        // Atomically reserve a slot in the result buffer
        int pos = atomic_inc(result_count);
        if (pos < 1024) { // limit to avoid overflow
            for (int i = 0; i < 8; ++i) {
                results[pos * 8 + i] = str[i];
            }
        }
    }
}
