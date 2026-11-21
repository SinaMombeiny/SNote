#ifndef SNOTE_CORE_HPP
#define SNOTE_CORE_HPP

#include <string>

namespace SNoteCore {

void initialize();
std::string title();
std::string body();
void setTitle(const char *value);
void setBody(const char *value);
void save();

}

#endif
