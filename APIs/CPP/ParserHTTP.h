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


#ifndef INCLUDE_PARSERHTTP_H
#define INCLUDE_PARSERHTTP_H

#include "Export.h"

//HTTP error codes

// 2xx - Successful
#define HTTP_OK 				200
#define HTTP_CREATED				201
#define HTTP_ACCEPTED				202

// 3xx - Redirection
#define HTTP_SEE_OTHER				303

// 4xx - Client Error
#define HTTP_BAD_REQUEST 			400
#define HTTP_UNAUTHORIZED			401
#define HTTP_FORBIDDEN				403
#define HTTP_NOT_FOUND 				404
#define HTTP_METHOD_NOT_ALLOWED		        405
#define HTTP_NOT_ACCEPTABLE			406
#define HTTP_UNSUPPORTED_MEDIA_TYPE             415

// 5xx - Server Error
#define HTTP_INTERNAL_SERVER_ERROR 	        500
#define HTTP_NOT_IMPLEMENTED		        501


#include <string>
#include <map>
#include <vector>

using namespace std;

class ParamHTTP {

  string nome;
  string valor;

 public:

  // ctor
  ParamHTTP(string n, string v);
  // gets
  string getNome();
  string getValor();
};


class LIBRARY_EXPORT ParserHTTP {

  string cabecalho;
  string endCab;
  string endLine;
  string metodo;
  string recurso;
  string cgi;
  string versao;
  string retcode;
  map<string, string> parametros;
  map<string, string>::iterator parsit;

 public:

  // constructor 
  ParserHTTP(); 

  // adiciona bytes a string do cabecalho (lidos do socket)
  // retorna true se o cabecalho estiver completo
  bool addBytes(char *bytes, int len);

  // parse
  bool parse();

  // operacao
  string getMethod();

  // recurso
  string getResource();

  // altera recurso (grupos)
  void setResource(string res);

  // CGI
  string getCGI();

  // altera CGI (grupos)
  void setCGI(string c);

  // versao
  string getVersion();

  // return code
  string getRetCode();

  // retorna o numero de parametros
  int numPars();

  // obtem um parametro especifico
  // retorna "" se o parametro nao existe
  string getPar(string nome);
};


#endif
