#ifndef PERMS_H
#define PERMS_H
#include <sys/_types/_mode_t.h>
#include <sys/_types/_s_ifmt.h>
#include <string.h>
#include <sys/stat.h>

void perms_to_string(mode_t mode, char str[11]);

#endif
