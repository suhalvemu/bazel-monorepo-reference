#include "apps/c-lib/greet.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main(void) {
    char *result = greet("Bazel");
    assert(strcmp(result, "Hello from C, Bazel!") == 0);
    free(result);

    char *result2 = greet("World");
    assert(strcmp(result2, "Hello from C, World!") == 0);
    free(result2);

    printf("All C tests passed.\n");
    return 0;
}
