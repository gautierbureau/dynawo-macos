cmake_minimum_required(VERSION 3.9.6 FATAL_ERROR)

project(ThirdParties CXX C)

include(ExternalProject)

include(ProcessorCount)
ProcessorCount(NUMBER_OF_PROCESSORS)
if(NUMBER_OF_PROCESSORS EQUAL 0)
  set(NUMBER_OF_PROCESSORS 1)
endif()

include(autoconf.cmake)
include(automake.cmake)