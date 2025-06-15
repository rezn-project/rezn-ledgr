#pragma once
#include <vector>
#include "host_descriptor.hpp"
#include "client.hpp"

class LedgerApiClient
{
public:
    LedgerApiClient(const std::string &socket_path);

    std::vector<HostDescriptor> list_hosts();
    bool add_host(const HostDescriptor &host, std::string *error = nullptr);
    // Add more methods as needed

private:
    LedgerClient client;
};