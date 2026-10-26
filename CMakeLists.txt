# SPDX-License-Identifier: Apache-2.0
#
# Starter application: blinks led0 and prints the board name on the console.
# Replace it with your firmware; the workspace builds whatever is here.

cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(sf2_app LANGUAGES C)

target_sources(app PRIVATE src/main.c)
