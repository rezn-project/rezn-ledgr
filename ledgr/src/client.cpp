// ledger_client.cpp
#include "client.hpp"
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <stdexcept>
#include <cstring>
#include <iostream>

LedgerClient::LedgerClient(const std::string &socket_path)
{
    if (auto res = conn.connect(sockpp::unix_address(socket_path)); !res)
    {
        throw std::runtime_error(
            std::string("Error connecting to UNIX socket at ") + socket_path +
            ": " + res.error_message());
    }
}

nlohmann::json LedgerClient::send_request(const nlohmann::json &req)
{
    std::string msg = req.dump() + "\n";

    // Write full request
    auto write_res = conn.write(msg);
    if (!write_res)
        throw std::runtime_error("sockpp: write() failed: " + write_res.error_message());

    if (write_res.value() != msg.size())
        throw std::runtime_error("sockpp: partial write: expected " + std::to_string(msg.size()) +
                                 ", got " + std::to_string(write_res.value()));

    // Read response until newline
    std::string resp;
    char ch;
    while (true)
    {
        sockpp::result<size_t> read_res;
        do
        {
            read_res = conn.read(&ch, 1);
        } while (!read_res && errno == EINTR);

        if (!read_res)
            throw std::runtime_error("sockpp: read() failed: " + read_res.error_message());

        if (read_res.value() == 0)
            throw std::runtime_error("sockpp: connection closed by peer");

        if (ch == '\n')
            break;

        resp += ch;

        if (resp.size() > 1024 * 1024)
            throw std::runtime_error("sockpp: response too large or missing newline");
    }

    try
    {
        return nlohmann::json::parse(resp);
    }
    catch (const std::exception &e)
    {
        throw std::runtime_error("JSON parse error: " + std::string(e.what()) + " - raw: " + resp);
    }
}
