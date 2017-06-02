/*
 *   HttpThru is a mobile robotics framework developed at the
 *   School of Electrical and Computer Engineering, University
 *   of Campinas, Brazil by Eleri Cardozo and collaborators.
 *   eleri@dca.fee.unicamp.br
 *
 *   Copyright (C) 2013 Eleri Cardozo
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

#include <time.h>
#include <stdio.h>
#include <sys/types.h>
#include <string.h>
#include <string>


#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>

#include <iostream>   // basic stream
#include <sstream>    // string I/O
#include <fstream>    // file I/O

#include "ParserHTTP.h"
#include "PlatformNetwork.h"

using namespace std;

/* write a CR-LF */
void writeCrLf(string *s) {
    char c = 13;
    *s += c;
    c = 10;
    *s += c;
}

void addBaseHttpHeader (string& response, int code, const string& ctype, unsigned int length) {
    time_t ttime;
    struct tm tmtime;
    char buff[256];

    if (code == HTTP_ACCEPTED) {
      response += "HTTP/1.1 202 ACCEPTED";
    } else {
      response += "HTTP/1.1 200 OK";
    }

    writeCrLf(&response);
    response += "Server: HttpThru";
    writeCrLf(&response);
    sprintf(buff, "Content-Length: %u", length);
    response += buff;
    writeCrLf(&response);
    response += "Content-Type: " + ctype;
    writeCrLf(&response);
    ttime = time(NULL);
    tmtime = *gmtime(&ttime);
    strftime(buff, 128, "Date: %a, %d %b %Y %H:%M:%S GMT", &tmtime);
    response += buff;
}

// send an HTTP response (a string)
int sendStringHttpResponse(int fd, const string content, string ctype, int responseCode) {
    fd_set fds;
    struct timeval timeout;
    int n;
    string reply;

    FD_ZERO(&fds);   
    FD_SET(fd, &fds);
    timeout.tv_sec = 5;
    timeout.tv_usec = 0;

    addBaseHttpHeader (reply, responseCode, ctype, content.length());

    // additional headers
    writeCrLf(&reply);
    reply += "Cache-Control: no-cache";

    // end of header
    writeCrLf(&reply);
    writeCrLf(&reply);

    reply += content;

    n = select(fd+1, (fd_set *)0, &fds, (fd_set *)0, &timeout);
    if(n != 1) return(-1);
    if(send(fd, reply.c_str(), reply.length(), 0) == (int)reply.length())
      return 0;
    return(-1);
}

// send an HTTP response (a C++ file)
int sendFileHttpResponse(int fd, ifstream* content, int len, string ctype, int responseCode) {
    fd_set fds;
    struct timeval timeout;
    int n;
    string reply;

    FD_ZERO(&fds);   
    FD_SET(fd, &fds);
    timeout.tv_sec = 5;
    timeout.tv_usec = 0;

    addBaseHttpHeader(reply, responseCode, ctype, (unsigned int) len);

    // additional headers
    if(len == 0) {  // probably a OPTIONS
        writeCrLf(&reply);
        reply += "Allow: GET, POST, OPTIONS";
    }

    // end of header
    writeCrLf(&reply);
    writeCrLf(&reply);

    n = select(fd+1, (fd_set *)0, &fds, (fd_set *)0, &timeout);
    if(n != 1) return(-1);

    // send header
    if(send(fd, reply.c_str(), reply.length(), 0) != (int)reply.length())
      return(-1);

    // send file
    char c[256];
    int i;
    while(len > 0) {
      content->read(c, 256);
      i = content->gcount();
      if(i < 0 || send(fd, c, i, 0) != i) return(-1);
      len -= i;
    }
    return(0);
}

// send an HTTP response (generic stream)
int sendHttpResponse(int fd, ios* content, string ctype, int responseCode) {
  ostringstream * stringContent = dynamic_cast<ostringstream*>(content);
  if (stringContent != NULL) {
    return sendStringHttpResponse(fd, stringContent->str(), ctype, responseCode);
  }

  ifstream * fileContent = dynamic_cast<ifstream*>(content);
  if (fileContent != NULL) {
    // get file size
    fileContent->seekg(0, ifstream::end);
    int fileSize = fileContent->tellg(); 
    fileContent->seekg(0, ifstream::beg);

    return sendFileHttpResponse(fd, fileContent, fileSize, ctype, responseCode);
  }
  
  return(-1);
}

// send an error response
int sendHttpErrorResponse(int fd, int code) {
    struct timeval timeout;
    fd_set fds;
    time_t ttime;
    struct tm tmtime;
    int n;
    string reply;
    char buff[256];
    const char *message;

    FD_ZERO(&fds);   
    FD_SET(fd, &fds);
    timeout.tv_sec = 5;
    timeout.tv_usec = 0;

    switch(code) {

    //4xx - Client Error
    case 400: strcpy(buff, "HTTP/1.1 400 Bad Request"); 
      message = "400 Bad Request\n";
      break;
    case 401: strcpy(buff, "HTTP/1.1 401 Unauthorized");
      message = "401 Unauthorized\n";
      break;
    case 403: strcpy(buff, "HTTP/1.1 403 Forbiden");
      message = "403 Forbiden\n";
      break;
    case 404: strcpy(buff, "HTTP/1.1 404 Not Found");
      message = "404 Not Found\n";
      break;
    case 405: strcpy(buff, "HTTP/1.1 405 Method Not Allowed");
      message = "405 Method not Allowed\n";
      break;
    case 406: strcpy(buff, "HTTP/1.1 406 Not Acceptable");
      message = "406 Not Acceptable\n";
      break;
    case 415: strcpy(buff, "HTTP/1.1 415 Unsupported Media Type");
      message = "415 Unsupported Media Type\n";
      break;

    //5xx - Server Error
    case 500: strcpy(buff, "HTTP/1.1 500 Internal Server Error");
      message = "500 Internal Server Error\n";
      break;
    case 501: strcpy(buff, "HTTP/1.1 501 Not Implemented");
      message = "501 Not Implemented\n";
      break;
    default: return(0);
    }

    reply += buff;
    writeCrLf(&reply);
    reply += "Server: RestThru";
    writeCrLf(&reply);
    sprintf(buff, "Content-Length: %u", strlen(message));
    reply += buff;
    writeCrLf(&reply);
    reply += "Content-Type: text/plain";
    writeCrLf(&reply);
    ttime = time(NULL);
    tmtime = *gmtime(&ttime);
    strftime(buff, 128, "Date: %a, %d %b %Y %H:%M:%S GMT", &tmtime);
    reply += buff;
    writeCrLf(&reply);
    writeCrLf(&reply);
    reply += message;

    n = select(fd+1, (fd_set *)0, &fds, (fd_set *)0, &timeout);
    if(n != 1) return(-1);
    return(send(fd, reply.c_str(), reply.length(), 0));
}




// send an HTTP request and get the reply
int sendHttpRequest(string url, string auth)
{
  struct sockaddr_in server; 
  int fd;
  static char buff[64];

  // break url
  if(url.find("http://") == string::npos) return(-1);
  size_t ind = url.find(":", 7);
  if(ind == string::npos) return(-1);
  string host = url.substr(7, ind-7);
  size_t ind2 = url.find("/", ind);
  if(ind2 == string::npos) return(-1);
  string port = url.substr(ind+1, ind2-ind-1);
  string query = url.substr(ind2);

  server.sin_family      = AF_INET;
  server.sin_port        = htons((unsigned short)atoi(port.c_str()));
  server.sin_addr.s_addr = inet_addr(host.c_str());

  string request;
  request += "GET ";
  request += query;
  request += " HTTP/1.1";
  writeCrLf(&request);
  request += "Host: ";
  request += host;
  if(auth.size() > 0) {
    writeCrLf(&request);
    request += "Authorization: Basic ";
    request += auth;
  }
  writeCrLf(&request);
  writeCrLf(&request);

  if ((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    perror("Socket()");
    return 0;
  }
   
  if (connect(fd, (struct sockaddr *)&server, sizeof(server)) < 0) {
    perror("Connect()");
    closesocket(fd);
    return 0;
  }

  if(send(fd, request.c_str(), request.length(), 0) != (int)request.length())
    return 0;

  // consume the reply
  while(recv(fd, buff, 64, 0) > 0);
  closesocket(fd);
  return 1;
}


// send an HTTP request and get the reply
int sendHttpRequest(string url)
{
  return(sendHttpRequest(url, ""));
}

// send an HTTP request and get the reply
// it is supposed that the user knows the return content type
int sendHttpRequest(string url, string op, unsigned char** buff, int * buffSize, string auth)
{
  struct sockaddr_in server; 
  int i, fd, size, clen = 0;
  static char buffCap[1024];
  string request, data;
  stringstream payload;
  int retCode = -20;

  * buffSize = 0;

  // break url
  if(url.find("http://") == string::npos) return(-1);
  unsigned long ind = url.find(":", 7);
  if(ind == string::npos) return(-2);
  string host = url.substr(7, ind-7);
  unsigned long ind2 = url.find("/", ind);
  if(ind2 == string::npos) return(-3);
  string port = url.substr(ind+1, ind2-ind-1);
  string query = url.substr(ind2);

  server.sin_family      = AF_INET;
  server.sin_port        = htons((unsigned short)atoi(port.c_str()));
  server.sin_addr.s_addr = inet_addr(host.c_str());

  request += op + " ";
  request += query;
  request += " HTTP/1.1";
  writeCrLf(&request);
  request += "Host: ";
  request += host;
  writeCrLf(&request);
  
  if(op == "PUT" || op == "POST"){
    if(buff != NULL){
      request += "Content-Type: application/json";
      writeCrLf(&request);
      request += "Content-Length: ";
      payload << (char*)*buff;
      data = payload.str();
      ostringstream sz;
      sz << data.size();
      request += sz.str();
      writeCrLf(&request);
    }
  }
 
  if(auth.size() > 0) {
    writeCrLf(&request);
    request += "Authorization: Basic ";
    request += auth;
    writeCrLf(&request);
  }
  writeCrLf(&request);

  if(op == "PUT" || op == "POST"){
    if(buff != NULL){
      request += data;
      writeCrLf(&request);
    }
  }

  if ((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    perror("Socket()");
    return -4;
  }
   
  if (connect(fd, (struct sockaddr *)&server, sizeof(server)) < 0) {
    perror("Connect()");
    closesocket(fd);
    return -5;
  }

  if(send(fd, request.c_str(), request.length(), 0) != (int)request.length())
    return -6;

  // get reply
  ParserHTTP p;

  int buffPos = 0;
  int dataSize = 0;
  bool isHeaderReceived = false;
  while(!isHeaderReceived) {
    buffPos = 0;
	dataSize = recv(fd, buffCap, 1024, 0);
	if (dataSize == 0) break;
    for (i = dataSize;i > 0; i--) {
      if(p.addBytes(&(buffCap[buffPos++]), 1)) {
        isHeaderReceived = true;
        break;
      }
    }
  }

  if(dataSize == 0) {
    closesocket(fd);
    return -7;
  }

  p.parse();

  retCode = atoi((p.getRetCode()).c_str());
  if (retCode == 0) {
    retCode = -10;
  }

  // header parsed
  string clength = p.getPar("Content-Length");
  clen = atoi(clength.c_str());

  *buff = (unsigned char *)malloc(clen + 1);
  memset(*buff, 0, clen + 1);
  int len = clen;

  size = (dataSize - buffPos);
  len -= size;
  memcpy((*buff), &(buffCap[buffPos]), size);  // write to buffer

  while(len > 0) {
    i = recv(fd, buffCap, 1024, 0);
    if(i <= 0) {
      closesocket(fd);
      free(*buff);
      return -8;   // server closed the connection
    }
    len -= i;
    memcpy((*buff + size), buffCap, i);  // write to buffer
    size += i;
  }

  closesocket(fd);
  
  * buffSize = clen;

  return retCode;
}


// send a POST request
int sendHttpPostRequest(string url, string data, string* ret)
{
  struct sockaddr_in server; 
  int i, fd, clen = 0;
  char ch;

  // break url
  if(url.find("http://") == string::npos) return(-1);
  unsigned long ind = url.find(":", 7);
  if(ind == string::npos) return(-1);
  string host = url.substr(7, ind-7);
  unsigned long ind2 = url.find("/", ind);
  if(ind2 == string::npos) return(-1);
  string port = url.substr(ind+1, ind2-ind-1);
  string query = url.substr(ind2);

  server.sin_family      = AF_INET;
  server.sin_port        = htons((unsigned short)atoi(port.c_str()));
  server.sin_addr.s_addr = inet_addr(host.c_str());

  string request;
  request += "POST ";
  request += query;
  request += " HTTP/1.1";
  writeCrLf(&request);
  request += "Host: ";
  request += host;
  writeCrLf(&request);
  request += "Connection: close";
  writeCrLf(&request);
  request += "Content-Length: ";
  ostringstream sz;
  sz << data.size();
  request += sz.str();
  writeCrLf(&request);
  writeCrLf(&request);
  request += data;

  if ((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    perror("Socket()");
    return -1;
  }
   
  if (connect(fd, (struct sockaddr *)&server, sizeof(server)) < 0) {
    perror("Connect()");
	closesocket(fd);
    return -1;
  }

  if(send(fd, request.c_str(), request.length(), 0) != (int)request.length())
    return -1;

  // get reply
  ParserHTTP p;

  while(1) {
    char c;
	i = recv(fd, &c, 1, 0);
	if(i <= 0) break;
    if(i == 1 && p.addBytes(&c, 1)) break;
  }

  if(i <= 0) {
    closesocket(fd);
    return -1;
  }

  p.parse();
  if(p.getRetCode() != "200") return -1;
  if(ret == NULL) return 0;

  // header parsed
  string clength = p.getPar("Content-Length");
  if(clength.size() > 0) clen = atoi(clength.c_str());
  else clen = 20000;

  int len = clen;
  int nbytes = 0;
  while(len > 0) {
    i = recv(fd, &ch, 1, 0);
    if(i <= 0) {
      break;
    }
    len -= i;
    nbytes += i;
    *ret += ch;
  }

  closesocket(fd);
  return nbytes;
}



// send an HTTP request and get the reply
// it is supposed that the user knows the return content type
int sendHttpRequest(string url, string op, unsigned char** buff, int * buffSize)
{
  return(sendHttpRequest(url, op, buff, buffSize, ""));
}

int sendHttpPostRequest(string url, string data)
{
  return(sendHttpPostRequest(url, data, NULL));
}


// send a redirect (3xx)
int sendHttpRedirect(int fd, int code, string location) {
  fd_set fds;
  int n;
  string reply;
  struct timeval timeout;

  switch(code) {

    // 303 See Other
    case 303: reply += "HTTP/1.1 303 See Other"; 
      break;

    // 301 Moved Permanently
    case 301: reply += "HTTP/1.1 301 Moved Permanently"; 
      break;

    default: return 0;
  }

  writeCrLf(&reply);
  reply += "Server: RestThru";
  writeCrLf(&reply);
  reply += "Location: ";
  reply += location;
  writeCrLf(&reply);
  writeCrLf(&reply);

  FD_ZERO(&fds);   
  FD_SET(fd, &fds);
  timeout.tv_sec = 5;
  timeout.tv_usec = 0;
  n = select(fd+1, (fd_set *)0, &fds, (fd_set *)0, &timeout);
  if(n != 1) return(-1);
  return(send(fd, reply.c_str(), reply.length(), 0));

  closesocket(fd);
  return 1;
}

// send a http created (201)
int sendHttpCreated(int fd, string location){
  fd_set fds;
  int n;
  string reply;
  struct timeval timeout;
  
  reply += "HTTP/1.1 201 Created";

  writeCrLf(&reply);
  reply += "Server: RestThru";
  writeCrLf(&reply);
  reply += "Location: ";
  reply += location;
  writeCrLf(&reply);
  writeCrLf(&reply);

  FD_ZERO(&fds);   
  FD_SET(fd, &fds);
  timeout.tv_sec = 5;
  timeout.tv_usec = 0;
  n = select(fd+1, (fd_set *)0, &fds, (fd_set *)0, &timeout);
  if(n != 1) return(-1);
  return(send(fd, reply.c_str(), reply.length(), 0));

  closesocket(fd);
  return 1;
}
