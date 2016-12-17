#include <stdio.h>


struct data {
    int id;
    int value;
};


int func1(int foo, char *bar) {
    int a = 0;
    int b = 10;
    char* v = "foo bar bar";
    char *missing;
    struct data data1 = {1,2};

    return b / a;
}

int func2(void) {
    int c = 123;
    int b = 456;

    return func1(1000, "value");
}

int func3(char *handler, int value, void *nothing) {
    return func2();
}

int func4(void) {
    return func3("handler 1", 100, NULL);
}

int main(int argc, char **argv) {
    printf("result: %d", func4());

    return 1;
}
