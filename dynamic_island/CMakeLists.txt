cmake_minimum_required(VERSION 3.19)
project(DynamicIsland LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Network DBus Concurrent)

add_subdirectory(config-app)

qt_add_qml_module(IslandBackend
    URI IslandBackend
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/IslandBackend
    SOURCES
        backend/SysBackend.h
        backend/SysBackend.cpp
        backend/SystemServices.h
        backend/SystemServices.cpp
        backend/CompositorBackend.h
        backend/CompositorBackend.cpp
        backend/StyleTokensBackend.h
        backend/StyleTokensBackend.cpp
        backend/FileShelfModel.h
        backend/FileShelfModel.cpp
        backend/UserConfigBackend.h
        backend/UserConfigBackend.cpp
        backend/BluetoothPairingAgent.h
        backend/BluetoothPairingAgent.cpp
        backend/WifiController.h
        backend/WifiController.cpp
        backend/WifiNetworkModel.h
        backend/WifiNetworkModel.cpp
)

target_include_directories(IslandBackend PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/backend)
target_link_libraries(IslandBackend PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Network Qt6::DBus Qt6::Concurrent udev)
