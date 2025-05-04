#define CL_TARGET_OPENCL_VERSION 120
#include <CL/cl.h>
#include <fstream>
#include <iostream>
#include <vector>
#include <string>
#include <chrono>

void cl_check_for_error(cl_int err, const char *msg)
{
    if (err != CL_SUCCESS)
    {
        printf("Fatal CL Error %d when trying to execute %s\n", err, msg);
        exit(EXIT_FAILURE);
    }
}

cl_platform_id get_cl_platform()
{
    cl_int err;
    cl_uint num_platforms;

    err = clGetPlatformIDs(0, NULL, &num_platforms);
    cl_check_for_error(err, "clGetPlatformIDs - Getting number of available OpenCL platforms");

    if (num_platforms == 0)
    {
        std::cerr << "No OpenCL platforms found.\n";
        exit(1);
    }

    std::vector<cl_platform_id> platforms(num_platforms);

    err = clGetPlatformIDs(num_platforms, platforms.data(), nullptr);
    cl_check_for_error(err, "clGetPlatformIDs - Getting list of availble OpenCL platforms");

    cl_platform_id chosen_platform = platforms[0];

    return chosen_platform;
}

cl_device_id get_cl_device(cl_platform_id chosen_platform)
{
    cl_int err;
    cl_uint num_devices;

    err = clGetDeviceIDs(chosen_platform, CL_DEVICE_TYPE_ALL, 0, nullptr, &num_devices);
    cl_check_for_error(err, "clGetDeviceIDs - Getting number of available OpenCL devices");

    if (num_devices == 0)
    {
        std::cerr << "No OpenCL devices found.\n";
        return 0;
    }

    std::vector<cl_device_id> devices(num_devices);

    err = clGetDeviceIDs(chosen_platform, CL_DEVICE_TYPE_ALL, num_devices, devices.data(), NULL);
    cl_check_for_error(err, "clGetDeviceIDs - Getting list of available OpenCL devices");

    cl_device_id chosen_device = devices[0];

    return chosen_device;
}

void display_device_name(cl_device_id chosen_device)
{
    cl_int err;
    char device_name[128];

    err = clGetDeviceInfo(chosen_device, CL_DEVICE_NAME, sizeof(device_name), device_name, nullptr);
    cl_check_for_error(err, "clGetDeviceInfo - Getting name of chosen OpenCL device");
    std::cout << "Using device: " << device_name << "\n";
}

std::string load_kernel_source(const std::string &filepath)
{
    std::ifstream file(filepath);
    if (!file.is_open())
    {
        throw std::runtime_error("Failed to open kernel file: " + filepath);
    }
    return std::string((std::istreambuf_iterator<char>(file)),
                       std::istreambuf_iterator<char>());
}

const std::string KERNEL_SOURCE = load_kernel_source("backend/seed_filter.cl");

// void launch_kernel(cl_kernel kernel, cl_mem outputBuffer, cl_command_queue queue, int N, cl_int err)
// {
//     // Set kernel arguments
//     clSetKernelArg(kernel, 0, sizeof(cl_mem), &outputBuffer);
//     clSetKernelArg(kernel, 1, sizeof(int), &N);

//     // Launch kernel
//     size_t globalWorkSize = N;
//     err = clEnqueueNDRangeKernel(queue, kernel, 1, nullptr, &globalWorkSize, nullptr, 0, nullptr, nullptr);
//     clFinish(queue);
// }

void generate_build_program_error(cl_program program, cl_device_id chosen_device)
{
    // Get and print build log on error
    size_t logSize;
    clGetProgramBuildInfo(program, chosen_device, CL_PROGRAM_BUILD_LOG, 0, nullptr, &logSize);
    std::vector<char> log(logSize);
    clGetProgramBuildInfo(program, chosen_device, CL_PROGRAM_BUILD_LOG, logSize, log.data(), nullptr);
    std::cerr << "Build log:\n"
              << log.data() << "\n";
    exit(1);
}

void perform_cleanup(cl_mem results_buffer, cl_kernel kernel, cl_program program, cl_command_queue queue, cl_context context)
{
    clReleaseMemObject(results_buffer);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);
}

int main()
{
    cl_platform_id chosen_platform = get_cl_platform();
    cl_device_id chosen_device = get_cl_device(chosen_platform);
    display_device_name(chosen_device);

    cl_int err;

    cl_context context = clCreateContext(nullptr, 1, &chosen_device, nullptr, nullptr, &err);
    cl_command_queue queue = clCreateCommandQueue(context, chosen_device, 0, &err);

    const char *src = KERNEL_SOURCE.c_str();
    size_t srcSize = KERNEL_SOURCE.size();

    cl_program program = clCreateProgramWithSource(context, 1, &src, nullptr, &err);
    err = clBuildProgram(program, 1, &chosen_device, nullptr, nullptr, nullptr);
    if (err != CL_SUCCESS)
    {
        generate_build_program_error(program, chosen_device);
    }

    cl_kernel kernel = clCreateKernel(program, "seed_filter", &err);

    // Define size and create buffers
    std::vector<int> result(1);
    cl_mem results_buffer = clCreateBuffer(context, CL_MEM_WRITE_ONLY, sizeof(int) * N, nullptr, &err);

    // launch_kernel(kernel, outputBuffer, queue, N, err);

    ulong offset = 0; 

    clSetKernelArg(kernel, 0, sizeof(cl_mem), &results_buffer);
    clSetKernelArg(kernel, 1, sizeof(cl_mem), &NUM_RESULTS);
    clSetKernelArg(kernel, 2, sizeof(cl_ulong), &offset);

    while true { 

    }
        
    // Launch kernel
    // size_t globalWorkSize = N;
    // err = clEnqueueNDRangeKernel(queue, kernel, 1, nullptr, &globalWorkSize, nullptr, 0, nullptr, nullptr);
    // clFinish(queue);

    // Read back result
    // clEnqueueReadBuffer(queue, outputBuffer, CL_TRUE, 0, sizeof(int) * N, result.data(), 0, nullptr, nullptr);

    // // Output results
    // std::cout << "Seed Filter:\n";
    // for (int i = 0; i < N; ++i)
    // {
    //     std::cout << result[i] << " ";
    // }
    // std::cout << "\n";

    // Cleanup
    perform_cleanup(results_buffer, kernel, program, queue, context);

    return 0;
}


// size_t global_size = 1000000;
// size_t local_size = 256;
// ulong offset = 0;

// while (result_count < desired_count) {
//     clSetKernelArg(kernel, 0, sizeof(cl_mem), &results_buf);
//     clSetKernelArg(kernel, 1, sizeof(cl_mem), &result_count_buf);
//     clSetKernelArg(kernel, 2, sizeof(cl_ulong), &offset);

//     clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &global_size, &local_size, 0, NULL, NULL);
//     offset += global_size;
// }
