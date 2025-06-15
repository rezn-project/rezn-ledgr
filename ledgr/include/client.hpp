// ledger_client.hpp
#pragma once
#include <string>
#include <nlohmann/json.hpp>

class LedgerClient
{
public:
    LedgerClient(const std::string &socket_path);
    ~LedgerClient();
    nlohmann::json send_request(const nlohmann::json &req);

private:
    int sock_fd;
};