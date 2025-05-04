cmake_minimum_required(VERSION 3.10)
project(OpenCLFibonacci)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)

find_package(OpenCL REQUIRED)

add_executable(OpenCLSeedFilter backend/main.cpp)

target_link_libraries(OpenCLSeedFilter OpenCL::OpenCL)
