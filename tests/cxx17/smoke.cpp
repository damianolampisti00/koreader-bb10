// C++17 smoke test for the GCC 9.3 BB10 toolchain.
#include <atomic>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <memory>
#include <mutex>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <thread>
#include <variant>
#include <vector>

static std::optional<int> half(int x) {
    if (x % 2) return std::nullopt;
    return x / 2;
}

int main() {
    int fails = 0;
#define CHECK(c) do { if (!(c)) { std::printf("FAIL %s\n", #c); ++fails; } else std::printf("ok   %s\n", #c); } while (0)

    CHECK(half(4).value_or(-1) == 2 && !half(3));
    std::variant<int, std::string> v = std::string("x");
    CHECK(std::holds_alternative<std::string>(v));
    std::string_view sv = "hello world";
    CHECK(sv.substr(6) == "world");
    CHECK(std::to_string(42) == "42");
    CHECK(std::fabs(std::sqrt(2.0) * std::sqrt(2.0) - 2.0) < 1e-9);
    CHECK(std::isnan(std::nan("")));

    bool caught = false;
    try { throw std::runtime_error("boom"); }
    catch (const std::exception &e) { caught = std::string(e.what()) == "boom"; }
    CHECK(caught);

    std::atomic<int> n{0};
    std::mutex m;
    std::vector<std::thread> ts;
    for (int i = 0; i < 4; ++i)
        ts.emplace_back([&] { for (int j = 0; j < 1000; ++j) { std::lock_guard<std::mutex> g(m); ++n; } });
    for (auto &t : ts) t.join();
    CHECK(n == 4000);

    auto p = std::make_unique<std::vector<int>>(3, 7);
    CHECK(p->size() == 3);

    std::error_code ec;
    auto cwd = std::filesystem::current_path(ec);
    CHECK(!ec && !cwd.empty());
    std::printf("cwd=%s\n", cwd.c_str());

    std::printf(fails ? "RESULT FAIL %d\n" : "RESULT OK\n", fails);
    return fails;
}
