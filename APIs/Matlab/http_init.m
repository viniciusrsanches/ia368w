% result = http_init(sessid)
%
% Set paths for http_xxx functions
%
% Input:
% - sessid: the REALabs session ID (not needed on simulated robots)
%
% Output:
% - none

function result = http_init(sessid)
   global http_handler_inst https_handler_inst;
   addpath('~/Desktop/APIs/Matlab/jsonlab');
   addpath('~/Desktop/APIs/Matlab/robot');
   javaaddpath('~/Desktop/APIs/Matlab');
   http_handler_inst = javaObject('resthru.HttpClient');
   https_handler_inst = javaObject('resthru.HttpsClient');
   % check if sessid was passed
   if nargin == 1
     http_handler_inst.setCookie(sessid);
     https_handler_inst.setCookie(sessid);
   end
end
