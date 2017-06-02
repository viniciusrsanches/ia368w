//
// C++ API
//

#include <time.h>
#include <string.h>
#include <list>
#include <cstring>
#include <string>
#include <vector>
#include <iostream>
#include <stdio.h>

#include <log4cplus/logger.h>
#include <log4cplus/configurator.h>
#include <log4cplus/loggingmacros.h>
#include <log4cplus/fileappender.h>
#include <log4cplus/layout.h>

#include <boost/chrono.hpp>

using namespace std;

#include "HttpClient.h"
#include "HttpUtil.h"
#include "JsonUtil.h"
#include "PlatformNetwork.h"

HttpClient::HttpClient() {
  init();
}

HttpClient::HttpClient(string s, string u) {
  setSessid(s);
  setUrl(u);

  init();
}

void HttpClient::init() {
  // Enable and configure logging
  if ( FILE * confFile = fopen("restthru_api_log.properties", "r") ) {
    fclose(confFile);
    log4cplus::PropertyConfigurator::doConfigure("restthru_api_log.properties");
    log4cplus::Logger logger = log4cplus::Logger::getInstance("restthru_api");
  } else {
    log4cplus::Logger logger = log4cplus::Logger::getInstance("restthru_api");
    if ( (logger.getAllAppenders()).empty() ) {
      string logFileName = "restthru_api.log";
#if defined(_WIN32)
      const int maxPath = _MAX_DRIVE + _MAX_DIR + _MAX_FNAME + _MAX_EXT;
      char exePath[maxPath];
	  if( GetModuleFileName( NULL, exePath, maxPath ) ) {
        char exeName[_MAX_FNAME];
        exeName[0] = NULL;
        _splitpath(exePath, NULL, NULL, exeName, NULL);
        logFileName = string(exeName) + "_api.log";
      }
#endif

      log4cplus::SharedAppenderPtr rfap(new log4cplus::RollingFileAppender(logFileName, 500 * 1024 * 1024, 5, false));
      std::auto_ptr<log4cplus::Layout> slp = std::auto_ptr<log4cplus::Layout> (new log4cplus::PatternLayout("%m%n"));
      rfap->setLayout(slp);
      logger.addAppender(rfap);
    }
  }

#if defined(_WIN32)
  WSADATA wsaData;
  int iResult;
  
  // Initialize Winsock
  iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
  if (iResult != 0) {
    printf("WSAStartup failed: %d\n", iResult);
  }
#endif

  boost::chrono::high_resolution_clock::time_point timeReference = boost::chrono::high_resolution_clock::now();
  boost::chrono::high_resolution_clock::time_point epoch;
  boost::chrono::microseconds elapsed_epoch_ms = boost::chrono::duration_cast<boost::chrono::microseconds>(timeReference - epoch);
  std::time_t now = boost::chrono::system_clock::to_time_t(boost::chrono::system_clock::now());
  log4cplus::Logger logger = log4cplus::Logger::getInstance("restthru_api");
  LOG4CPLUS_INFO(logger, std::endl << "HttpClient initialized : " << elapsed_epoch_ms << " " << std::ctime(&now));
}

HttpClient::~HttpClient() {
#if defined(_WIN32)
  WSACleanup();
#endif
}

string HttpClient::getUrl() {
  return url;
}

string HttpClient::getSessid() {
  return sessid;
}

void HttpClient::setUrl(string u) {
  log4cplus::Logger logger = log4cplus::Logger::getInstance("restthru_api");
  LOG4CPLUS_DEBUG(logger, "HttpClient url: " << u << std::endl);

  url = u;
}

void HttpClient::setSessid(string s) {
  log4cplus::Logger logger = log4cplus::Logger::getInstance("restthru_api");
  LOG4CPLUS_DEBUG(logger, "HttpClient session id: " << s << std::endl);

  sessid = s;
}

// write a CR-LF (defined in HttpParser.cpp)
extern void writeCrLf(string *s);

//perform operation
char* HttpClient::doWork(string op, string resource, unsigned char* data){
  int size = 0;
  boost::chrono::high_resolution_clock::time_point start = boost::chrono::high_resolution_clock::now();
  int ret = sendHttpRequest(url + resource, op, &data, &size);
  boost::chrono::high_resolution_clock::time_point end = boost::chrono::high_resolution_clock::now();
  boost::chrono::microseconds elapsed_us = boost::chrono::duration_cast<boost::chrono::microseconds>(end - start);
  boost::chrono::high_resolution_clock::time_point epoch;
  boost::chrono::microseconds elapsed_epoch_ms = boost::chrono::duration_cast<boost::chrono::microseconds>(start - epoch);

  if (size <= 0) {
    data = (unsigned char *)malloc(1);
    data[0] = 0;
    size = 1;
  }

  log4cplus::Logger logger = log4cplus::Logger::getInstance("restthru_api");
  LOG4CPLUS_DEBUG(logger, elapsed_epoch_ms.count() << " " << elapsed_us.count() << " " << ret << " " << size << " " << op << " " << (url+resource));

  return (char*)data;
}

Json::Value HttpClient::get(string resource){
  char *ret;
  Json::Value root;
  Json::Reader reader;
  ret = doWork("GET", resource, NULL);
  string r(ret);
  free(ret);
  if(reader.parse(r, root)){
    return root;
  } else {
    return jsonNull;
  }
}

int HttpClient::put(string resource, unsigned char* data){
  doWork("PUT", resource, data);
  return 0;
}

int HttpClient::post(string resource, unsigned char* data){
  doWork("POST", resource, data);
  return 0;
}

int HttpClient::del(string resource){
  doWork("DELETE", resource, NULL);
  return 0;
}
