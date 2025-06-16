cmake_minimum_required(VERSION 3.20)

project(rezn-ledger LANGUAGES C CXX)

# ----------------------------------------------------------------------
# Toolchain / language settings
# ----------------------------------------------------------------------
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)     # nice for clangd / IDEs

# ----------------------------------------------------------------------
# Project layout helpers
# ----------------------------------------------------------------------
set(DEPS_DIR    ${CMAKE_CURRENT_SOURCE_DIR}/../deps)
set(SRC_DIR     ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include)

# ----------------------------------------------------------------------
# Sources
# ----------------------------------------------------------------------
set(PROJECT_SOURCES
    # --- your own code -------------------------------------------------
    ${SRC_DIR}/client.cpp          #  ←  new libcurl-based client
    ${SRC_DIR}/api_client.cpp
    ${SRC_DIR}/ledger.cpp

    # --- ImGui ---------------------------------------------------------
    ${DEPS_DIR}/imgui/imgui.cpp
    ${DEPS_DIR}/imgui/imgui_draw.cpp
    ${DEPS_DIR}/imgui/imgui_widgets.cpp
    ${DEPS_DIR}/imgui/imgui_tables.cpp
    ${DEPS_DIR}/imgui/misc/cpp/imgui_stdlib.cpp
    ${DEPS_DIR}/imgui/imgui_demo.cpp

    # --- ImTui ---------------------------------------------------------
    ${DEPS_DIR}/imtui/src/imtui-impl-ncurses.cpp
    ${DEPS_DIR}/imtui/src/imtui-impl-text.cpp
)

# ----------------------------------------------------------------------
# Third-party libraries
# ----------------------------------------------------------------------
find_package(Curses REQUIRED)        # ncurses for ImTui
find_package(CURL   REQUIRED)        # libcurl ≥ 7.40, needs UDS support
find_package(Threads REQUIRED)       # libcurl may link against it

# ----------------------------------------------------------------------
# Target
# ----------------------------------------------------------------------
add_executable(rezn-ledger ${PROJECT_SOURCES})

target_include_directories(rezn-ledger PRIVATE
    ${INCLUDE_DIR}                    # your own headers
    ${DEPS_DIR}                       # umbrella include for other deps
    ${DEPS_DIR}/json/single_include   # nlohmann/json
    ${DEPS_DIR}/imgui
    ${DEPS_DIR}/imtui/include
)

target_link_libraries(rezn-ledger
    PRIVATE
    ${CURSES_LIBRARIES}
    Threads::Threads
    CURL::libcurl                    # imported target from find_package(CURL)
)
