#pragma once
#include <string>
#include <nlohmann/json.hpp>

struct HostDescriptor
{
    std::string id;
    std::string name;
    std::string host;
};

inline void to_json(nlohmann::json &j, const HostDescriptor &h)
{
    j = nlohmann::json{{"id", h.id}, {"name", h.name}, {"host", h.host}};
}
inline void from_json(const nlohmann::json &j, HostDescriptor &h)
{
    j.at("id").get_to(h.id);
    j.at("name").get_to(h.name);
    j.at("host").get_to(h.host);
}