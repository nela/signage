cmake_minimum_required(VERSION 3.16)

project(signage_player VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Qt6 packages
find_package(Qt6 REQUIRED COMPONENTS Core Quick Multimedia)

# Enable automatic MOC, UIC, RCC
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Add executable
add_executable(signage_player
    main.cpp
    qml.qrc
)

# Link Qt libraries
target_link_libraries(signage_player PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Multimedia
)

# Install
install(TARGETS signage_player
    RUNTIME DESTINATION bin
)
