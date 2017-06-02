#include <cstdlib>

#include "HttpClient.h"

int main(int argc, char** argv){

  int cod = 0;

  HttpClient robot = HttpClient();
  robot.setUrl("http://127.0.0.1:4950");

  char* data;
  Json::Value root;
  
  if (argc <= 2) {
    cerr << "Usage: " << argv[0] << " <method> <url> [data]" << endl;
    exit (1);
  }
  string method = argv[1];
  
  if(method == "GET"){
    root = robot.get(string(argv[2]));
  }else if(method == "DELETE"){
    cod = robot.del(string(argv[2]));
  } else if (argc <= 3) {
    cerr << "Usage: " << argv[0] << " <method> <url> <data>" << endl;
    exit (1);
  }else if(method == "PUT"){
    data = argv[3];
    cod = robot.put(string(argv[2]), (unsigned char*)data);
  }else if(method == "POST"){
    data = argv[3];
    cod = robot.post(string(argv[2]), (unsigned char*)data);
  }else{
    cout << "Method not supported." << endl;
    return 0;
  }

  cout << "Return: " << cod << endl;
  cout << root.toStyledString() << endl;

  return 0;

}
