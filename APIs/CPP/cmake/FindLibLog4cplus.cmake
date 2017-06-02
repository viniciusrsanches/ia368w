# - Try to find liblog4cplus
# Once done this will define
#  LIBLOG4CPLUS_FOUND - System has liblog4cplus
#  LIBLOG4CPLUS_INCLUDE_DIRS - The liblog4cplus include directories
#  LIBLOG4CPLUS_LIBRARIES - The libraries needed to use liblog4cplus
#  LIBLOG4CPLUS_DEFINITIONS - Compiler switches required for using liblog4cplus

find_path(LIBLOG4CPLUS_INCLUDE_DIR log4cplus/logger.h
            /usr/include
            /usr/local/include
			"C:/log4cplus_src/include"
)

if(UNIX)
  find_library(LIBLOG4CPLUS_LIBRARY NAMES log4cplus liblog4cplus
               PATHS 
                 /usr/lib
                 /usr/local/lib
  )
else()
  FIND_LIBRARY(LIBLOG4CPLUS_LIBRARY_DEBUG NAMES log4cplusD
               PATHS 
                 "C:/log4cplus/win_lib"
    )
  FIND_LIBRARY(LIBLOG4CPLUS_LIBRARY_RELEASE NAMES log4cplus
               PATHS 
                 "C:/log4cplus/win_lib"
    )
endif()

if(UNIX)  
  set(LIBLOG4CPLUS_LIBRARIES ${LIBLOG4CPLUS_LIBRARY})
  set(LIBLOG4CPLUS_INCLUDE_DIRS ${LIBLOG4CPLUS_INCLUDE_DIR})
else()
  list(APPEND LIBLOG4CPLUS_LIBRARIES optimized ${LIBLOG4CPLUS_LIBRARY_RELEASE})
  list(APPEND LIBLOG4CPLUS_LIBRARIES debug ${LIBLOG4CPLUS_LIBRARY_DEBUG})
  set(LIBLOG4CPLUS_INCLUDE_DIRS ${LIBLOG4CPLUS_INCLUDE_DIR})
endif()


include(FindPackageHandleStandardArgs)
if(UNIX)
  find_package_handle_standard_args(LibLog4cplus  DEFAULT_MSG
                                    LIBLOG4CPLUS_LIBRARY LIBLOG4CPLUS_INCLUDE_DIR)
else()
  find_package_handle_standard_args(LibLog4cplus  DEFAULT_MSG
                                    LIBLOG4CPLUS_LIBRARY_RELEASE LIBLOG4CPLUS_LIBRARY_DEBUG LIBLOG4CPLUS_INCLUDE_DIR)
endif()

mark_as_advanced(LIBLOG4CPLUS_INCLUDE_DIR LIBLOG4CPLUS_LIBRARY)
