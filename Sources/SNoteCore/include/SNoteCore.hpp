#ifndef SNOTE_CORE_HPP
#define SNOTE_CORE_HPP

#include <string>

namespace SNoteCore {

void initialize();
const char *title();
const char *body();
void setTitle(const char *value);
void setBody(const char *value);
void save();

}

#endif
