# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.31

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/dylan/Documents/03_Coding/Balatro/Seed-Filter

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/dylan/Documents/03_Coding/Balatro/Seed-Filter/build

# Include any dependencies generated for this target.
include CMakeFiles/OpenCLSeedFilter.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/OpenCLSeedFilter.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/OpenCLSeedFilter.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/OpenCLSeedFilter.dir/flags.make

CMakeFiles/OpenCLSeedFilter.dir/codegen:
.PHONY : CMakeFiles/OpenCLSeedFilter.dir/codegen

CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.o: CMakeFiles/OpenCLSeedFilter.dir/flags.make
CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.o: /home/dylan/Documents/03_Coding/Balatro/Seed-Filter/backend/main.cpp
CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.o: CMakeFiles/OpenCLSeedFilter.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/dylan/Documents/03_Coding/Balatro/Seed-Filter/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.o"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.o -MF CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.o.d -o CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.o -c /home/dylan/Documents/03_Coding/Balatro/Seed-Filter/backend/main.cpp

CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/dylan/Documents/03_Coding/Balatro/Seed-Filter/backend/main.cpp > CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.i

CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/dylan/Documents/03_Coding/Balatro/Seed-Filter/backend/main.cpp -o CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.s

# Object files for target OpenCLSeedFilter
OpenCLSeedFilter_OBJECTS = \
"CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.o"

# External object files for target OpenCLSeedFilter
OpenCLSeedFilter_EXTERNAL_OBJECTS =

OpenCLSeedFilter: CMakeFiles/OpenCLSeedFilter.dir/backend/main.cpp.o
OpenCLSeedFilter: CMakeFiles/OpenCLSeedFilter.dir/build.make
OpenCLSeedFilter: CMakeFiles/OpenCLSeedFilter.dir/compiler_depend.ts
OpenCLSeedFilter: /usr/lib64/libOpenCL.so
OpenCLSeedFilter: CMakeFiles/OpenCLSeedFilter.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --bold --progress-dir=/home/dylan/Documents/03_Coding/Balatro/Seed-Filter/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX executable OpenCLSeedFilter"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/OpenCLSeedFilter.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/OpenCLSeedFilter.dir/build: OpenCLSeedFilter
.PHONY : CMakeFiles/OpenCLSeedFilter.dir/build

CMakeFiles/OpenCLSeedFilter.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/OpenCLSeedFilter.dir/cmake_clean.cmake
.PHONY : CMakeFiles/OpenCLSeedFilter.dir/clean

CMakeFiles/OpenCLSeedFilter.dir/depend:
	cd /home/dylan/Documents/03_Coding/Balatro/Seed-Filter/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/dylan/Documents/03_Coding/Balatro/Seed-Filter /home/dylan/Documents/03_Coding/Balatro/Seed-Filter /home/dylan/Documents/03_Coding/Balatro/Seed-Filter/build /home/dylan/Documents/03_Coding/Balatro/Seed-Filter/build /home/dylan/Documents/03_Coding/Balatro/Seed-Filter/build/CMakeFiles/OpenCLSeedFilter.dir/DependInfo.cmake "--color=$(COLOR)"
.PHONY : CMakeFiles/OpenCLSeedFilter.dir/depend

