/*
 * tests/unit/test_perms.c
 *
 * Simple unit test for perms_to_string. The function is copied verbatim
 * from source/system_programs/ld.c so the test is self-contained: no
 * extra .h or .c file is needed. If you change ld.c, update the copy
 * below too.
 *
 * Run with:
 *   make unit
 */

#include "unity.h"

#include <string.h>
#include <sys/stat.h>

/* ---- copy of perms_to_string from source/system_programs/ld.c ---- */
static void perms_to_string(mode_t mode, char str[11])
{
    strcpy(str, "----------");

    if (S_ISDIR(mode)) str[0] = 'd';
    if (S_ISCHR(mode)) str[0] = 'c';
    if (S_ISBLK(mode)) str[0] = 'b';

    if (mode & S_IRUSR) str[1] = 'r';
    if (mode & S_IWUSR) str[2] = 'w';
    if (mode & S_IXUSR) str[3] = 'x';

    if (mode & S_IRGRP) str[4] = 'r';
    if (mode & S_IWGRP) str[5] = 'w';
    if (mode & S_IXGRP) str[6] = 'x';

    if (mode & S_IROTH) str[7] = 'r';
    if (mode & S_IWOTH) str[8] = 'w';
    if (mode & S_IXOTH) str[9] = 'x';
}
/* ------------------------------------------------------------------ */

void setUp(void) {}
void tearDown(void) {}

static void test_empty_mode(void) {
    char buf[16];
    perms_to_string(0, buf);
    TEST_ASSERT_EQUAL_STRING("----------", buf);
}

static void test_regular_file_0644(void) {
    char buf[16];
    perms_to_string(S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH, buf);
    TEST_ASSERT_EQUAL_STRING("-rw-r--r--", buf);
}

static void test_directory_0755(void) {
    char buf[16];
    mode_t m = S_IFDIR
             | S_IRUSR | S_IWUSR | S_IXUSR
             | S_IRGRP            | S_IXGRP
             | S_IROTH            | S_IXOTH;
    perms_to_string(m, buf);
    TEST_ASSERT_EQUAL_STRING("drwxr-xr-x", buf);
}

static void test_all_owner_perms_only(void) {
    char buf[16];
    perms_to_string(S_IRUSR | S_IWUSR | S_IXUSR, buf);
    TEST_ASSERT_EQUAL_STRING("-rwx------", buf);
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_empty_mode);
    RUN_TEST(test_regular_file_0644);
    RUN_TEST(test_directory_0755);
    RUN_TEST(test_all_owner_perms_only);
    return UNITY_END();
}
