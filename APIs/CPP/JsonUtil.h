/*
 *   HttpThru is a mobile robotics framework developed at the
 *   School of Electrical and Computer Engineering, University
 *   of Campinas, Brazil by Eleri Cardozo and collaborators.
 *   eleri@dca.fee.unicamp.br
 *
 *   Copyright (C) 2011 Eleri Cardozo
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#if defined(_WIN32)
#ifdef restThru_API_EXPORTS // (the default macro in Visual Studio)
#define JSON_DATA_EXPORT __declspec(dllexport)
#else
#define JSON_DATA_EXPORT __declspec(dllimport)
#endif
#else
#if __GNUC__ >= 4
#define JSON_DATA_EXPORT __attribute__ ((visibility ("default")))
#else
#define JSON_DATA_EXPORT
#endif
#endif

#include "Export.h"

#include <stdio.h>
#include <sys/types.h>
#include <iostream>
#include <sstream>
#include <string>
#include <string.h>
#include <stdlib.h>
// #include <unistd.h>
#include <time.h>
// #include <dlfcn.h>

#if defined(_WIN32) || defined(__APPLE__)
#include <json/json.h>
#else
#include <jsoncpp/json/json.h>
#endif

using namespace std;

// get a Json node (XPath style)
LIBRARY_EXPORT Json::Value getJsonNode(Json::Value root, string path);

// get specific Json data
LIBRARY_EXPORT bool getJsonInt(Json::Value root, string path, int* data);
LIBRARY_EXPORT bool getJsonDouble(Json::Value root, string path, double* data);
LIBRARY_EXPORT bool getJsonString(Json::Value root, string path, string* data);
LIBRARY_EXPORT bool getJsonBool(Json::Value root, string path, bool* data);

// Json null value
JSON_DATA_EXPORT extern Json::Value jsonNull;
