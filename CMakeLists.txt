cmake_minimum_required(VERSION 3.20)

project(rezn-ledger LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 23)

set(DEPS ${CMAKE_CURRENT_SOURCE_DIR}/deps)

set(LEDGER_BASE_PATH ${CMAKE_CURRENT_SOURCE_DIR})

set(LEDGER_SRC
        ${LEDGER_BASE_PATH}/src/ledger.cpp
)

find_package(Curses REQUIRED)
include_directories(${CURSES_INCLUDE_DIR})

add_executable(rezn-ledger
    ${LEDGER_SRC}
    ${DEPS}/imgui/imgui.cpp
    ${DEPS}/imgui/imgui_draw.cpp
    ${DEPS}/imgui/imgui_widgets.cpp
    ${DEPS}/imgui/imgui_tables.cpp
    ${DEPS}/imgui/misc/cpp/imgui_stdlib.cpp
    ${DEPS}/imgui/imgui_demo.cpp
    ${DEPS}/imtui/src/imtui-impl-ncurses.cpp
    ${DEPS}/imtui/src/imtui-impl-text.cpp
)

target_include_directories(
    rezn-ledger PRIVATE
    ${LEDGER_BASE_PATH}/include
    ${DEPS}
    ${DEPS}/imgui
    ${DEPS}/imtui/include
)

target_link_libraries(rezn-ledger ${CURSES_LIBRARIES})
