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


#include <string>
#include <iostream>   // basic stream
#include <fstream>    // file I/O

using namespace std;


// send Http response ok (200 or 202)
int sendHttpResponse(int fd, ios* content, string ctype, int responseCode);
int sendStringHttpResponse(int fd, const string content, string ctype, int responseCode);
int sendFileHttpResponse(int fd, ifstream* content, int len, string ctype, int responseCode);

// send Http error respnse
int sendHttpErrorResponse(int fd, int code);

// send an HTTP request and drop the reply
int sendHttpRequest(string url);
int sendHttpRequest(string url, string auth);
int sendHttpPostRequest(string url, string data);

// send an HTTP request and get the reply
// it is supposed that the user knows the return content type
int sendHttpRequest(string url, string op, unsigned char** buff, int * buffSize);
int sendHttpRequest(string url, string op, unsigned char** buff, int * buffSize, string auth);
int sendHttpPostRequest(string url, string data, string* ret);

// send a redirect (3xx)
int sendHttpRedirect(int fd, int code, string location);

// send http created (201)
int sendHttpCreated(int fd, string location);
