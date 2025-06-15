// ledger_client.hpp
#pragma once
#include <string>
#include <nlohmann/json.hpp>

#include "sockpp/unix_connector.h"

class LedgerClient
{
public:
    LedgerClient(const std::string &socket_path);
    nlohmann::json send_request(const nlohmann::json &req);

private:
    int sock_fd;
    sockpp::unix_connector conn;
};