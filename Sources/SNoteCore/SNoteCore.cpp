#include "SNoteCore.hpp"

#include <CoreFoundation/CoreFoundation.h>

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <string>

namespace {

struct Document {
    std::string title = "Untitled";
    std::string body;
};

Document document;
std::mutex documentMutex;
bool initialized = false;

std::string jsonEscape(const std::string &value) {
    std::string escaped;
    escaped.reserve(value.size());
    for (unsigned char character : value) {
        switch (character) {
        case '"':
            escaped += "\\\"";
            break;
        case '\\':
            escaped += "\\\\";
            break;
        case '\b':
            escaped += "\\b";
            break;
        case '\f':
            escaped += "\\f";
            break;
        case '\n':
            escaped += "\\n";
            break;
        case '\r':
            escaped += "\\r";
            break;
        case '\t':
            escaped += "\\t";
            break;
        default:
            if (character < 0x20) {
                char buffer[7];
                std::snprintf(buffer, sizeof(buffer), "\\u%04x", character);
                escaped += buffer;
            } else {
                escaped += static_cast<char>(character);
            }
        }
    }
    return escaped;
}

std::string jsonUnescape(const std::string &value) {
    std::string result;
    result.reserve(value.size());
    for (size_t index = 0; index < value.size(); ++index) {
        if (value[index] != '\\' || index + 1 >= value.size()) {
            result += value[index];
            continue;
        }
        ++index;
        switch (value[index]) {
        case '"': result += '"'; break;
        case '\\': result += '\\'; break;
        case '/': result += '/'; break;
        case 'b': result += '\b'; break;
        case 'f': result += '\f'; break;
        case 'n': result += '\n'; break;
        case 'r': result += '\r'; break;
        case 't': result += '\t'; break;
        case 'u':
            if (index + 4 < value.size()) {
                char encoded[5] = {
                    value[index + 1], value[index + 2],
                    value[index + 3], value[index + 4], '\0'
                };
                unsigned int codepoint = 0;
                if (std::sscanf(encoded, "%x", &codepoint) == 1) {
                    if (codepoint < 0x80) {
                        result += static_cast<char>(codepoint);
                    } else if (codepoint < 0x800) {
                        result += static_cast<char>(0xc0 | (codepoint >> 6));
                        result += static_cast<char>(0x80 | (codepoint & 0x3f));
                    } else {
                        result += static_cast<char>(0xe0 | (codepoint >> 12));
                        result += static_cast<char>(0x80 | ((codepoint >> 6) & 0x3f));
                        result += static_cast<char>(0x80 | (codepoint & 0x3f));
                    }
                }
                index += 4;
            }
            break;
        default: result += value[index]; break;
        }
    }
    return result;
}

std::string jsonStringValue(const std::string &json, const std::string &key) {
    const std::string needle = "\"" + key + "\"";
    size_t keyPosition = json.find(needle);
    if (keyPosition == std::string::npos) {
        return {};
    }
    size_t colon = json.find(':', keyPosition + needle.size());
    if (colon == std::string::npos) {
        return {};
    }
    size_t openingQuote = json.find('"', colon + 1);
    if (openingQuote == std::string::npos) {
        return {};
    }
    size_t closingQuote = openingQuote + 1;
    bool escaped = false;
    for (; closingQuote < json.size(); ++closingQuote) {
        if (json[closingQuote] == '\\' && !escaped) {
            escaped = true;
            continue;
        }
        if (json[closingQuote] == '"' && !escaped) {
            break;
        }
        escaped = false;
    }
    if (closingQuote >= json.size()) {
        return {};
    }
    return jsonUnescape(json.substr(openingQuote + 1, closingQuote - openingQuote - 1));
}

Document parseDocument(const std::string &json) {
    Document parsed;
    size_t firstObject = json.find('{');
    if (firstObject == std::string::npos) {
        return parsed;
    }
    std::string title = jsonStringValue(json.substr(firstObject), "title");
    std::string body = jsonStringValue(json.substr(firstObject), "body");
    if (!title.empty()) {
        parsed.title = title;
    }
    parsed.body = body;
    return parsed;
}

std::filesystem::path storageDirectory() {
    const char *home = std::getenv("HOME");
    if (home == nullptr) {
        return std::filesystem::temp_directory_path() / "SNote";
    }
    return std::filesystem::path(home) / "Library" / "Application Support" / "SNote";
}

std::filesystem::path storageFile() {
    return storageDirectory() / "Document.json";
}

std::string readFile(const std::filesystem::path &path) {
    std::ifstream stream(path);
    if (!stream) {
        return {};
    }
    return std::string(std::istreambuf_iterator<char>(stream), std::istreambuf_iterator<char>());
}

bool loadLegacyPreference() {
    CFPropertyListRef value = CFPreferencesCopyAppValue(
        CFSTR("SNote.notes"), kCFPreferencesCurrentApplication);
    if (value == nullptr) {
        return false;
    }
    bool loaded = false;
    if (CFGetTypeID(value) == CFDataGetTypeID()) {
        auto data = static_cast<CFDataRef>(value);
        const UInt8 *bytes = CFDataGetBytePtr(data);
        CFIndex length = CFDataGetLength(data);
        if (bytes != nullptr && length > 0) {
            Document migrated = parseDocument(std::string(
                reinterpret_cast<const char *>(bytes), static_cast<size_t>(length)));
            document = migrated;
            loaded = true;
        }
    }
    CFRelease(value);
    return loaded;
}

void writeLegacyPreference() {
    std::string legacy = "[{\"title\":\"" + jsonEscape(document.title) +
        "\",\"body\":\"" + jsonEscape(document.body) + "\",\"modifiedAt\":0}]";
    CFDataRef data = CFDataCreate(
        kCFAllocatorDefault,
        reinterpret_cast<const UInt8 *>(legacy.data()),
        static_cast<CFIndex>(legacy.size()));
    CFPreferencesSetAppValue(
        CFSTR("SNote.notes"), data, kCFPreferencesCurrentApplication);
    CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
    CFRelease(data);
}

void saveDocumentLocked() {
    std::error_code error;
    std::filesystem::create_directories(storageDirectory(), error);
    if (error) {
        return;
    }

    const auto seconds = std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    std::ofstream stream(storageFile(), std::ios::trunc);
    if (stream) {
        stream << "{\"title\":\"" << jsonEscape(document.title)
               << "\",\"body\":\"" << jsonEscape(document.body)
               << "\",\"modifiedAt\":" << seconds << '}';
    }
    writeLegacyPreference();
}

}

namespace SNoteCore {

void initialize() {
    std::lock_guard<std::mutex> lock(documentMutex);
    if (initialized) {
        return;
    }
    initialized = true;

    std::string stored = readFile(storageFile());
    if (!stored.empty()) {
        document = parseDocument(stored);
        return;
    }

    if (!loadLegacyPreference()) {
        document = Document{};
    }
    saveDocumentLocked();
}

const char *title() {
    std::lock_guard<std::mutex> lock(documentMutex);
    return document.title.c_str();
}

const char *body() {
    std::lock_guard<std::mutex> lock(documentMutex);
    return document.body.c_str();
}

void setTitle(const char *value) {
    std::lock_guard<std::mutex> lock(documentMutex);
    document.title = value == nullptr ? "" : value;
    saveDocumentLocked();
}

void setBody(const char *value) {
    std::lock_guard<std::mutex> lock(documentMutex);
    document.body = value == nullptr ? "" : value;
    saveDocumentLocked();
}

void save() {
    std::lock_guard<std::mutex> lock(documentMutex);
    saveDocumentLocked();
}

}
