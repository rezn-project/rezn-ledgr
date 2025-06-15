#include "api_client.hpp"

LedgerApiClient::LedgerApiClient(const std::string &socket_path)
    : client(socket_path) {}

std::vector<HostDescriptor> LedgerApiClient::list_hosts()
{
    nlohmann::json req = {{"op", "list"}};
    nlohmann::json resp = client.send_request(req);
    std::vector<HostDescriptor> hosts;
    if (resp.contains("entries") && resp["entries"].is_array())
    {
        for (const auto &jhost : resp["entries"])
        {
            hosts.push_back(jhost.get<HostDescriptor>());
        }
    }
    return hosts;
}

bool LedgerApiClient::add_host(const HostDescriptor &host, std::string *error)
{
    nlohmann::json req = {{"op", "create"}, {"entry", host}};
    nlohmann::json resp = client.send_request(req);
    if (resp.contains("status") && resp["status"] == "ok")
    {
        return true;
    }
    if (error && resp.contains("message"))
    {
        *error = resp["message"].get<std::string>();
    }
    return false;
}