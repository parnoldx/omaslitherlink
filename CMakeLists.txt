cmake_minimum_required(VERSION 3.21)
project(omarchy-slitherlink VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.2 REQUIRED COMPONENTS Core Gui Qml Quick Test)

set(CPP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cpp)

set(OMARCHY_SLITHERLINK_SOURCES
    ${CPP_DIR}/difficulty.cpp
    ${CPP_DIR}/generator.cpp
    ${CPP_DIR}/puzzle_bank.cpp
    ${CPP_DIR}/storage.cpp
    ${CPP_DIR}/theme.cpp
    ${CPP_DIR}/game.cpp
)

add_library(omarchy_slitherlink_lib STATIC ${OMARCHY_SLITHERLINK_SOURCES})
target_include_directories(omarchy_slitherlink_lib PUBLIC ${CPP_DIR})
target_link_libraries(omarchy_slitherlink_lib PUBLIC Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick)

add_executable(omarchy-slitherlink ${CPP_DIR}/main.cpp)
target_link_libraries(omarchy-slitherlink PRIVATE omarchy_slitherlink_lib)

enable_testing()
add_executable(test_game ${CPP_DIR}/tests/test_game.cpp)
target_link_libraries(test_game PRIVATE omarchy_slitherlink_lib Qt6::Test)
add_test(NAME test_game COMMAND test_game)

install(TARGETS omarchy-slitherlink RUNTIME DESTINATION bin)
