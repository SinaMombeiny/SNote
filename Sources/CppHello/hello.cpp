#include "hello.h"

#include <string>

static const std::string message = "Hello, world!";

extern "C" const char *hello_cpp_message(void) {
    return message.c_str();
}
