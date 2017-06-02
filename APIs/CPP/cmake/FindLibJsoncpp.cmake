# - Try to find libjsoncpp
# Once done this will define
#  LIBJSONCPP_FOUND - System has libjsoncpp
#  LIBJSONCPP_INCLUDE_DIRS - The libjsoncpp include directories
#  LIBJSONCPP_LIBRARIES - The libraries needed to use libjsoncpp
#  LIBJSONCPP_DEFINITIONS - Compiler switches required for using libjsoncpp

find_path(LIBJSONCPP_INCLUDE_DIR NAMES jsoncpp/json/json.h json/json.h
          PATHS
            /usr/local/include
            /usr/include
			"C:/jsoncpp/include"
)

if(UNIX)
  find_library(LIBJSONCPP_LIBRARY NAMES jsoncpp libjsoncpp json_vc100_libmt
               PATHS 
                 /usr/local/lib
                 /usr/lib
                 "C:/jsoncpp/win_lib"
  )
else()
  FIND_LIBRARY(LIBJSONCPP_LIBRARY_DEBUG NAMES lib_json
               PATHS 
                 "C:/jsoncpp/win_lib/Debug"
    )
  FIND_LIBRARY(LIBJSONCPP_LIBRARY_RELEASE NAMES lib_json
               PATHS 
                 "C:/jsoncpp/win_lib/Release"
    )
endif()

if(UNIX)  
  set(LIBJSONCPP_LIBRARIES ${LIBJSONCPP_LIBRARY})
  set(LIBJSONCPP_INCLUDE_DIRS ${LIBJSONCPP_INCLUDE_DIR})
else()
  list(APPEND LIBJSONCPP_LIBRARIES optimized ${LIBJSONCPP_LIBRARY_RELEASE})
  list(APPEND LIBJSONCPP_LIBRARIES debug ${LIBJSONCPP_LIBRARY_DEBUG})
  set(LIBJSONCPP_INCLUDE_DIRS ${LIBJSONCPP_INCLUDE_DIR})
endif()

include(FindPackageHandleStandardArgs)
if(UNIX)
  find_package_handle_standard_args(LibJsoncpp  DEFAULT_MSG
                                    LIBJSONCPP_LIBRARY LIBJSONCPP_INCLUDE_DIR)
else()
  find_package_handle_standard_args(LibJsoncpp  DEFAULT_MSG
                                    LIBJSONCPP_LIBRARY_RELEASE LIBJSONCPP_LIBRARY_DEBUG LIBJSONCPP_INCLUDE_DIR)
endif()

mark_as_advanced(LIBJSONCPP_INCLUDE_DIR LIBJSONCPP_LIBRARY)
