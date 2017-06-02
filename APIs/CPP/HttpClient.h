//
// C++ API for P3-DX
//

#ifndef __HTTPCLIENT_H
#define __HTTPCLIENT_H

#include <list>
#include <string>
#include <vector>
#include <iostream>

#include "Export.h"

#if defined(_WIN32) || defined(__APPLE__)
#include <json/json.h>
#else
#include <jsoncpp/json/json.h>
#endif

using namespace std;


class LIBRARY_EXPORT HttpClient {

    string url;
    string sessid;

    void init();

   // get dowork
    char* doWork(string op, string resource, unsigned char* data);

 public:

    HttpClient();
    HttpClient(string s, string u);

    ~HttpClient();

    string getUrl();

    string getSessid();

    void setUrl(string u);

    void setSessid(string s);

    Json::Value get(string resource);

    int put(string resource, unsigned char* data);

    int post(string resource, unsigned char* data);

    int del(string resource);
};


#endif
