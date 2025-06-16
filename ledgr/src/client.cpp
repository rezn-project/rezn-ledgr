#include "client.hpp"
#include <sstream>

LedgerClient::LedgerClient(const std::string &socket_path,
                           std::chrono::seconds timeout)
    : curl_{curl_easy_init()},
      socket_path_{socket_path},
      timeout_sec_{static_cast<long>(timeout.count())}
{
    if (!curl_)
        throw std::runtime_error("curl_easy_init() failed");

    curl_easy_setopt(curl_.get(), CURLOPT_UNIX_SOCKET_PATH, socket_path_.c_str());
    curl_easy_setopt(curl_.get(), CURLOPT_URL, "http://localhost/"); // path irrelevant for UDS
    curl_easy_setopt(curl_.get(), CURLOPT_WRITEFUNCTION, &LedgerClient::write_cb);
    curl_easy_setopt(curl_.get(), CURLOPT_TIMEOUT, timeout_sec_);
    curl_easy_setopt(curl_.get(), CURLOPT_NOSIGNAL, 1L); // avoid SIGPIPE
}

LedgerClient::~LedgerClient() = default;

size_t LedgerClient::write_cb(char *ptr, size_t size, size_t nmemb, void *userdata)
{
    auto *buf = static_cast<std::string *>(userdata);
    buf->append(ptr, size * nmemb);
    return size * nmemb;
}

nlohmann::json LedgerClient::send_request(const nlohmann::json &req)
{
    const std::string body = req.dump();
    std::string resp_body;

    struct curl_slist *hdrs = nullptr;
    hdrs = curl_slist_append(hdrs, "Content-Type: application/json");

    curl_easy_setopt(curl_.get(), CURLOPT_POST, 1L);
    curl_easy_setopt(curl_.get(), CURLOPT_HTTPHEADER, hdrs);
    curl_easy_setopt(curl_.get(), CURLOPT_POSTFIELDS, body.c_str());
    curl_easy_setopt(curl_.get(), CURLOPT_POSTFIELDSIZE, body.size());
    curl_easy_setopt(curl_.get(), CURLOPT_WRITEDATA, &resp_body);

    CURLcode rc = curl_easy_perform(curl_.get());
    curl_slist_free_all(hdrs); // free header list immediately

    if (rc != CURLE_OK)
        throw std::runtime_error(std::string("libcurl: ") + curl_easy_strerror(rc));

    long http_status = 0;
    curl_easy_getinfo(curl_.get(), CURLINFO_RESPONSE_CODE, &http_status);
    if (http_status != 200)
        throw std::runtime_error("Server returned HTTP " + std::to_string(http_status) +
                                 " – body: " + resp_body);

    try
    {
        return nlohmann::json::parse(resp_body);
    }
    catch (const std::exception &e)
    {
        throw std::runtime_error("JSON parse error: " + std::string(e.what()) +
                                 " – raw: " + resp_body);
    }
}
