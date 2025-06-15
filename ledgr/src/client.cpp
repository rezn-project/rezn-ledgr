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
    sock_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock_fd < 0)
        throw std::runtime_error("socket() failed");

    sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    if (socket_path.size() >= sizeof(addr.sun_path))
        throw std::runtime_error("Socket path too long");

    std::strncpy(addr.sun_path, socket_path.c_str(), sizeof(addr.sun_path) - 1);

    std::cerr << "[DEBUG] Connecting to socket: " << socket_path << std::endl;

    size_t len = offsetof(sockaddr_un, sun_path) + std::strlen(addr.sun_path);
    if (connect(sock_fd, (sockaddr *)&addr, len) < 0)
    {
        close(sock_fd);
        throw std::runtime_error("connect() failed");
    }
}

LedgerClient::~LedgerClient()
{
    if (sock_fd >= 0)
        close(sock_fd);
}

nlohmann::json LedgerClient::send_request(const nlohmann::json &req)
{
    std::string msg = req.dump() + "\n";

    std::cerr << "[DEBUG] Sending: " << msg << std::endl;

    size_t total_written = 0;
    while (total_written < msg.size())
    {
        ssize_t written = write(sock_fd, msg.c_str() + total_written, msg.size() - total_written);
        if (written < 0)
            throw std::runtime_error("write() failed");
        total_written += written;
    }

    std::string resp;
    char buf[1024];
    ssize_t n;
    while ((n = read(sock_fd, buf, sizeof(buf))) > 0)
    {
        resp.append(buf, n);
        if (!resp.empty() && resp.back() == '\n')
            break;
    }
    if (n < 0)
        throw std::runtime_error("read() failed");

    std::cerr << "[DEBUG] Raw response: " << resp << std::endl;

    return nlohmann::json::parse(resp);
}