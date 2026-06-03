#include "apps/c-lib/greet.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *greet(const char *name) {
    const char *prefix = "Hello from C, ";
    const char *suffix = "!";
    size_t len = strlen(prefix) + strlen(name) + strlen(suffix) + 1;
    char *result = malloc(len);
    snprintf(result, len, "%s%s%s", prefix, name, suffix);
    return result;
}
