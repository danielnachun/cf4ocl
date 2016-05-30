#!/usr/bin/env bats
#
# Test suite for ccl_c utility
#
# Author: Nuno Fachada <faken@fakenmc.com>
# Licence: GNU General Public License version 3 (GPLv3)
# Date: 2016
#

# ##################################### #
# Setup and teardown for each test case #
# ##################################### #

setup() {

	# ccl_c binary
	CCL_C_COM="@CMAKE_BINARY_DIR@/src/utils/ccl_c"

	# ccl_devinfo binary
	CCL_C_DEVINFO="@CMAKE_BINARY_DIR@/src/utils/ccl_devinfo"

	# How many devices?
	CCL_C_NDEVS=`${CCL_C_DEVINFO} | grep -c "\[ Device #"`

	# Device index to use in tests
	if [ -z ${CCL_C_DEV_IDX} ]
	then
		CCL_C_DEV_IDX="@TESTS_DEVICE_INDEX@"
	fi

	# OpenCL version of device platform
	CCL_C_OCL_VERSION=`${CCL_C_DEVINFO} -o -d ${CCL_C_DEV_IDX} -c VERSION | grep -o "OpenCL [1-9]\.[1-9]" | cut -d " " -f 2`

	# Test kernels folder
	CCL_C_K_FOLDER="@CMAKE_SOURCE_DIR@/tests/test_kernels"

	# Fully working kernels
	CCL_C_K_SUM="${CCL_C_K_FOLDER}/sum_full.cl"
	CCL_C_K_XOR="${CCL_C_K_FOLDER}/xor_full.cl"

	# Non-working kernel
	CCL_C_K_BAD="${CCL_C_K_FOLDER}/not_ok.cl"

	# Kernels requiring header to compile
	CCL_C_K_NEEDH_SUM="${CCL_C_K_FOLDER}/sum_needs_header.cl"
	CCL_C_K_NEEDH_XOR="${CCL_C_K_FOLDER}/xor_needs_header.cl"
	CCL_C_K_NEEDH_SUMXOR="${CCL_C_K_FOLDER}/sumxor_needs_two_headers.cl"

	# Function headers
	CCL_C_H_SUM="${CCL_C_K_FOLDER}/sum_impl.cl.h"
	CCL_C_H_XOR="${CCL_C_K_FOLDER}/xor_impl.cl.h"

	# Header names
	CCL_C_HNAME_SUM="sum_impl.cl.h"
	CCL_C_HNAME_XOR="xor_impl.cl.h"

	# Function implementations
	CCL_C_KIMPL_SUM="${CCL_C_K_FOLDER}/sum_impl.cl"
	CCL_C_KIMPL_XOR="${CCL_C_K_FOLDER}/xor_impl.cl"

	# Base name for temporary binary files
	CCL_C_TMP_BIN="@CMAKE_CURRENT_BINARY_DIR@/temp.bin"

}

teardown() {

	# Remove possible temporary files
	rm -f ${CCL_C_TMP_BIN}{1..2}

}

# ################################### #
# Test help, list and version options #
# ################################### #

# Test help option, which should return status 0.
@test "Help options" {

	run ${CCL_C_COM} -?
	[ "$status" -eq 0 ]

	run ${CCL_C_COM} --help
	[ "$status" -eq 0 ]

}

# Test version, which should return status 0.
@test "Get version" {

	run ${CCL_C_COM} --version
	[ "$status" -eq 0 ]

}

# Test device list, which should return status 0.
@test "List devices" {

	run ${CCL_C_COM} -l
	[ "$status" -eq 0 ]

	run ${CCL_C_COM} --list
	[ "$status" -eq 0 ]

}

# ############### #
# Test build task #
# ############### #

# Test simple build with one source file.
@test "Build with one source file" {

	run ${CCL_C_COM} -s ${CCL_C_K_SUM} -d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

}

# Test build with two source files.
@test "Build with two source files" {

	run ${CCL_C_COM} -s ${CCL_C_K_SUM} -s ${CCL_C_K_XOR} -d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

}

# Test build with one source, create binary, then with one binary.
@test "Build with one source, create binary, then with one binary" {

	# Test build with one source and create binary.
	run ${CCL_C_COM} -s ${CCL_C_K_SUM} -o ${CCL_C_TMP_BIN}1 -d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

	# Check if binary was created
	[ -f ${CCL_C_TMP_BIN}1 ]

	# Test build with one binary.
	run ${CCL_C_COM} -b ${CCL_C_TMP_BIN}1 -d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

}

# Test build with two binaries created from two different source files. */
@test "Build with two binaries created from two different source files" {

	# Test build with one source and create binary.
	run ${CCL_C_COM} -s ${CCL_C_K_SUM} -o ${CCL_C_TMP_BIN}1 -d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

	# Check if binary was created
	[ -f ${CCL_C_TMP_BIN}1 ]

	# Test build with another source and create another binary.
	run ${CCL_C_COM} -s ${CCL_C_K_XOR} -o ${CCL_C_TMP_BIN}2 -d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

	# Check if binary was created
	[ -f ${CCL_C_TMP_BIN}2 ]

	# Test build with two binaries. */
	run ${CCL_C_COM} -b ${CCL_C_TMP_BIN}1 -b ${CCL_C_TMP_BIN}2 -d \
		${CCL_C_DEV_IDX}

	# Error: builds can only be performed with one binary
	[ "$status" -ne 0 ]

}

# Test build with one binary and one source file.
@test "Build with one binary and one source file" {

	# Test build with one source and create binary.
	run ${CCL_C_COM} -s ${CCL_C_K_SUM} -o ${CCL_C_TMP_BIN}1 -d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

	# Check if binary was created
	[ -f ${CCL_C_TMP_BIN}1 ]

	# Test build with one binary and one source file.
	run ${CCL_C_COM} -s ${CCL_C_K_SUM} -b ${CCL_C_TMP_BIN}2 -d ${CCL_C_DEV_IDX}

	# Error: The build task requires either: 1) one or more source files; or,
	# 2) one binary file
	[ "$status" -ne 0 ]

}

# Test build with source headers.
@test "Build with source headers" {

	run ${CCL_C_COM} -h ${CCL_C_K_SUM} -d ${CCL_C_DEV_IDX}

	# Error: source headers can only be specified in the compile task
	[ "$status" -ne 0 ]
}

# Test build with erroneous source file.
@test "Build with erroneous source file" {

	run ${CCL_C_COM} -s ${CCL_C_K_BAD} -d ${CCL_C_DEV_IDX}

	# Error: build should not be successful with erroneous source file
	[ "$status" -ne 0 ]

}

# Test build with non-existing device.
@test "Build with non-existing device" {

	run ${CCL_C_COM} -s ${CCL_C_K_SUM} -d ${CCL_C_NDEVS}

	# Error: build should throw error if device does not exist
	[ "$status" -ne 0 ]

}

# Test build with non-existing file.
@test "Build with non-existing file" {

	run ${CCL_C_COM} -s this_file_does_not_exist.cl -d ${CCL_C_DEV_IDX}

	# Error: build should throw error if source file does not exist
	[ "$status" -ne 0 ]

}

# Test build with one source file with correct compiler options
@test "Build with one source file with correct compiler options" {

	run ${CCL_C_COM} -s ${CCL_C_K_SUM} -0 "-cl-fast-relaxed-math" \
		-d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

}

# Test build with one source file with incorrect compiler options
@test "Build with one source file with incorrect compiler options" {

	run ${CCL_C_COM} -s ${CCL_C_K_SUM} -0 "-an-incorrect-option" \
		-d ${CCL_C_DEV_IDX}

	# Error: incorrect compiler options
	[ "$status" -ne 0 ]

}

# ################# #
# Test compile task #
# ################# #

# Test compile with one source file.
@test "Compile with one source file" {

	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_SUM} -d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

}

# Test compile with two source files.
@test "Compile with two source files" {

	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_SUM} -s ${CCL_C_K_XOR} \
		-d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

}

# Test compile with one binary.
@test "Compile with one binary" {

	# Test compile with one source and create binary.
	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_SUM} -o ${CCL_C_TMP_BIN}1 \
		-d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

	# Check if binary was created
	[ -f ${CCL_C_TMP_BIN}1 ]

	# Test compile with one binary.
	run ${CCL_C_COM} -t 1 -b ${CCL_C_TMP_BIN}1 -d ${CCL_C_DEV_IDX}

	# Error: compilation does not support binaries
	[ "$status" -ne 0 ]

}

# Test compile with one binary and one source file.
@test "Compile with one binary and one source file" {

	# Test compile with one source and create binary.
	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_SUM} -o ${CCL_C_TMP_BIN}1 \
		-d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

	# Check if binary was created
	[ -f ${CCL_C_TMP_BIN}1 ]

	# Test compile with another source and the generated binary.
	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_XOR} -b ${CCL_C_TMP_BIN}1 \
		-d ${CCL_C_DEV_IDX}

	# Error: compilation does not support binaries
	[ "$status" -ne 0 ]

}

# Test compile with source headers.
@test "Compile with source headers" {

	run ${CCL_C_COM} -t 1 -h ${CCL_C_K_SUM} -d ${CCL_C_DEV_IDX}

	# Error: at least one source file must be specified
	[ "$status" -ne 0 ]

}

# Test compile with one source file and one source header.
@test "Compile with one source file and one source header" {

	# First, specify source header in -h parameter and header name in -n
	# parameter
	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_NEEDH_SUM} -h ${CCL_C_H_SUM} \
		-n ${CCL_C_HNAME_SUM} -d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

	# Second, pass include header path in compiler options
	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_NEEDH_SUM} -0 "-I ${CCL_C_K_FOLDER}" \
		-d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]
}

# Test compile with source file and two source headers with explicitly
# specified header names.
@test "Compile with one source file and two headers" {

	# First, specify source header in -h parameter and header name in -n
	# parameter
	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_NEEDH_SUMXOR} -h ${CCL_C_H_SUM} \
		-h ${CCL_C_H_XOR} -n ${CCL_C_HNAME_SUM} -n ${CCL_C_HNAME_XOR} \
		-d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

	# Second, pass include header path in compiler options
	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_NEEDH_SUMXOR} -0 "-I ${CCL_C_K_FOLDER}" \
		-d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]
}

# Test compile with source file and two correct source headers with explicitly
# incorrectly specified header names or location.
@test "Compile with one source file and two incorrectly specified headers" {

	# First, specify source header in -h parameter but don't specify header
	# names or location
	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_NEEDH_SUMXOR} -h ${CCL_C_H_SUM} \
		-h ${CCL_C_H_XOR} -d ${CCL_C_DEV_IDX}

	# Error: program will not find required headers
	[ "$status" -ne 0 ]

	# Second, specify source header in -h parameter and incorrect header names
	# in -n parameter
	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_NEEDH_SUMXOR} -h ${CCL_C_H_SUM} \
		-h ${CCL_C_H_XOR} -n bad_name1.cl.h -n bad_name2.cl.h \
		-d ${CCL_C_DEV_IDX}

	# Error: program will not find required headers
	[ "$status" -ne 0 ]

	# Third, pass incorrect include header path in compiler options
	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_NEEDH_SUMXOR} -0 "-I bad/folder" \
		-d ${CCL_C_DEV_IDX}

	# Error: program will not find required headers
	[ "$status" -ne 0 ]

}

# Test compile with source file and an erroneous source header.
@test "Compile with source file and an erroneous source header" {

	# First, specify source header in -h parameter and header name in -n
	# parameter
	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_NEEDH_SUM} -h ${CCL_C_K_BAD} \
		-n ${CCL_C_HNAME_SUM} -d ${CCL_C_DEV_IDX}

	# Error: header contains incorrect information
	[ "$status" -ne 0 ]

}

# Test compile with erroneous source file.
@test "Compile with erroneous source file" {

	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_BAD} -d ${CCL_C_DEV_IDX}

	# Error: compile should not be successful with erroneous source file
	[ "$status" -ne 0 ]

}

# Test compile with non-existing device.
@test "Compile with non-existing device" {

	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_SUM} -d ${CCL_C_NDEVS}

	# Error: compile should throw error if device does not exist
	[ "$status" -ne 0 ]

}

# Test compile with non-existing file.
@test "Compile with non-existing file" {

	run ${CCL_C_COM} -t 1 -s this_file_does_not_exist.cl -d ${CCL_C_DEV_IDX}

	# Error: compile should throw error if source file does not exist
	[ "$status" -ne 0 ]

}

# Test compile with one source file with correct compiler options
@test "Compile with one source file with correct compiler options" {

	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_SUM} -0 "-cl-fast-relaxed-math" \
		-d ${CCL_C_DEV_IDX}

	# There should be no problems
	[ "$status" -eq 0 ]

}

# Test compile with one source file with incorrect compiler options
@test "Compile with one source file with incorrect compiler options" {

	run ${CCL_C_COM} -t 1 -s ${CCL_C_K_SUM} -0 "-an-incorrect-option" \
		-d ${CCL_C_DEV_IDX}

	# Error: incorrect compiler options
	[ "$status" -ne 0 ]

}


# ############## #
# Test link task #
# ############## #

# Test link with one binary.

# Test link with two binaries.

# Test link with an invalid binary.

# Test link with a source file.

# Test link with one binary and one source.

# Test link with source headers.

# Test link with non-existing device.

# Test link with non-existing file.

# Test link with one binary with compiler options.

# Test link with one binary with incorrect compiler options.
