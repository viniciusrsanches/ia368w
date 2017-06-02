cmake_minimum_required (VERSION 2.8)

project (RestThru_API CXX)

if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set (CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "default install path" FORCE )
endif(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

set(CMAKE_BUILD_TYPE Debug)

set(CMAKE_CXX_COMPILER g++)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -fvisibility=hidden")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")

if(WIN32)
SET(Boost_ADDITIONAL_VERSIONS "1.51.0")
set(BOOST_ROOT "C:/Program Files/boost/")
set(Boost_USE_STATIC_LIBS OFF) 
set(Boost_USE_MULTITHREADED ON)  
set(Boost_USE_STATIC_RUNTIME OFF) 
endif(WIN32)

include_directories(${RestThru_API_SOURCE_DIR})
find_package(LibJsoncpp REQUIRED)
find_package(LibLog4cplus REQUIRED)
find_package(Boost COMPONENTS chrono system REQUIRED)

if(WIN32)
  set(LIBS ${LIBS} ws2_32)
  link_directories( ${Boost_LIBRARY_DIRS} )
  add_definitions(-DBOOST_ALL_DYN_LINK)
endif(WIN32)

include_directories(${RestThru_API_SOURCE_DIR} ${LIBJSONCPP_INCLUDE_DIRS} ${LIBLOG4CPLUS_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})

add_library(restThru_API SHARED
                     HttpClient.cpp
                     HttpUtil.cpp
                      JsonUtil.cpp
                      ParserHTTP.cpp
                      PlatformNetwork.cpp
                      StringTokenizer.cpp
)

set(LIBS ${LIBS} ${LIBJSONCPP_LIBRARIES} ${LIBLOG4CPLUS_LIBRARIES} ${Boost_CHRONO_LIBRARY}  ${Boost_SYSTEM_LIBRARY})
target_link_libraries(restThru_API ${LIBS})

add_executable(example example.cpp)
target_link_libraries(example restThru_API)

install(TARGETS restThru_API example
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
		ARCHIVE DESTINATION lib)
install(FILES ./HttpClient.h ./Export.h ./JsonUtil.h DESTINATION include)
install(FILES ./restthru_api_log.properties DESTINATION bin)
