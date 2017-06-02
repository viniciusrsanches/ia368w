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

/* 
 * Compilador CSP: classe que processa cabecalho HTTP
 *
 * Eleri Cardozo, jul 2011
 *
 */

#include <algorithm>
#include <map>
#include <string.h>
#include <string>

#include "ParserHTTP.h"
#include "StringTokenizer.h"

using namespace std;

// classe ParamHTTP

// ctor
ParamHTTP::ParamHTTP(string n, string v) {
  nome = n;
  valor = v;
}

// get
string ParamHTTP::getNome() {
  return nome;
}

string ParamHTTP::getValor() {
  return valor;
}


// classe ParserHTTP


// ctor 
ParserHTTP::ParserHTTP() {
  endCab = string("\r\n\r\n");
  endLine = string("\r\n");
}

// adiciona bytes a string do cabecalho (lidos do socket)
bool ParserHTTP::addBytes(char *bytes, int len) {
  cabecalho += string(bytes, len);
  if(cabecalho.find(endCab) != string::npos) return true;
  return false;
}

// parse
bool ParserHTTP::parse() {
  if(cabecalho.find(endCab) == string::npos) return false;
  bool isFirstLine = true;
  int nfrags;
  StringTokenizer lines(cabecalho, endLine);
  int nlines = lines.countTokens();
  string line, st;
  for(int i = 0; i < nlines; i++)
    {
      line = lines.nextToken();
      if(isFirstLine) {  // process first line
	isFirstLine = false;
	StringTokenizer firstLine(line, " ");
	// response
	if(line.find("HTTP/1") == 0) {
	  firstLine.nextToken();   // HTTP/1.1
	  retcode = firstLine.nextToken();
	}
	else  {  // request
	  int nfrags = firstLine.countTokens();
	  if(nfrags != 3) return false;
	  metodo = firstLine.nextToken();
	  string reccgi = firstLine.nextToken();
	  StringTokenizer rectok(reccgi, "?");
	  if(rectok.countTokens() == 2) {
	    recurso = rectok.nextToken();
	    cgi = "?" + rectok.nextToken();
	  } else recurso = reccgi;
	  versao = firstLine.nextToken();
	}
      } else {     // subsequent lines Par: Valor...
	StringTokenizer parLine(line, ":");
	nfrags = parLine.countTokens();
	if(nfrags < 2) {
	  // Axis sends TWO HTTP/1.1 200 OK ?????????                          
          if(strcmp(line.c_str(), "HTTP/") == 0) continue;
          else return false;
        }
        string nome = parLine.nextToken();
        string valor = parLine.nextToken();
	valor = valor.substr(1);  // remove blank after :
	while(parLine.hasMoreTokens()) {  // take remaining tokens
	  valor += ":" + parLine.nextToken();   // and add : that was droped
	}
	// HTTP headers are case-insensitive - RFC 2616 Section 4.2
	std::transform(nome.begin(), nome.end(), nome.begin(), ::tolower);

	parametros[nome] = valor;
      }
    }
  return true;
}

// operacao
string ParserHTTP::getMethod() {
  return metodo;
}

// recurso
string ParserHTTP::getResource() {
  return recurso;
}

// altera recurso
void ParserHTTP::setResource(string res){
	recurso = res;
}

// CGI
string ParserHTTP::getCGI() {
  return cgi;
}

// altera CGI
void ParserHTTP::setCGI(string c){
  cgi = c;
}

// versao
string ParserHTTP::getVersion() {
  return versao;
}

// Return code
string ParserHTTP::getRetCode() {
  return retcode;
}


// obtem numero de parametros
int ParserHTTP::numPars() {
  return((int)(parametros.size()));
}


// obtem parametro especifico
string ParserHTTP::getPar(string nome) {
  // HTTP headers are case-insensitive - RFC 2616 Section 4.2
  std::transform(nome.begin(), nome.end(), nome.begin(), ::tolower);

  map<string, string>::iterator it = parametros.find(nome);
  if(it == parametros.end()) return string("");
  return(it->second);
}

