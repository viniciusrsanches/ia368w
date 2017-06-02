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

#include <stdio.h>
#include <sys/types.h>
#include <iostream>
#include <sstream>
#include <string>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#include "JsonUtil.h"
#include "StringTokenizer.h"

// Json null value
Json::Value jsonNull;

using namespace std;

// get a Json node (XPath style)

Json::Value getJsonNode(Json::Value root, string path) {
  Json::Value v = root;
  if(! v.isObject()) return jsonNull;

  StringTokenizer strtok = StringTokenizer(path, "/");
  int cnt = strtok.countTokens();
  for(int i = 0; i < cnt; i++)
    {
      string elem = strtok.nextToken();
      if(! v.isMember(elem)) return jsonNull;
      v = v[elem];
    }
  return v;
}

// get specific Json data

bool getJsonInt(Json::Value root, string path, int* data) {
  Json::Value v = getJsonNode(root, path);
  if(v != jsonNull && v.isInt()) {
    *data = v.asInt();
    return true;
  }
  return false;
}

bool getJsonDouble(Json::Value root, string path, double* data) {
  Json::Value v = getJsonNode(root, path);
  if(v != jsonNull && v.isNumeric()) {
    *data = v.asDouble();
    return true;
  }
  return false;
}



bool getJsonString(Json::Value root, string path, string* data) {
  Json::Value v = getJsonNode(root, path);
  if(v != jsonNull && v.isString()) {
    *data = v.asString();
    return true;
  }
  return false;
}

bool getJsonBool(Json::Value root, string path, bool* data) {
  Json::Value v = getJsonNode(root, path);
  if(v != jsonNull && v.isBool()) {
    *data = v.asBool();
    return true;
  }
  return false;
}

