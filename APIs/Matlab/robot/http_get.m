% result = http_get(resource)
%
% Input:
% - resource: the URL of the resource (protocol can be http or https)
%
% Possible outputs:
% - the resource representation
% - empty string if no payload
% - NaN on HTTP error:
%   400 : Bad Request
%   401 : Unauthorized
%   403 : Forbiden
%   404 : Not Found
%   405 : Method not Allowed

function result = http_get(resource)
   global http_handler_inst https_handler_inst;
   % check if http or https
   type = strfind(resource, 'http://');
   if type == 1
     handler = http_handler_inst;
   else
     handler = https_handler_inst;
   end

   % get resource name
   name = '';
   inds = strfind(resource, '/');
   if isempty(inds) == false
     k = length(inds);
     k = inds(k) + 1;
     if k < length(resource) 
       name = substr(resource, k);
     end
   end
   inds = strfind(name, '?');
   if isempty(inds) == false
     k = inds(1) - 1;
     if k > 0
     name = substr(name, 1, k);
     end
   end

   % do http transaction
   content = handler.sendRequest('GET', resource, '', '');
   retcode = handler.getStatusCode;
   if strcmp(retcode, '200') == 1 
     ctype = handler.getContentType;
     if strcmp(ctype, 'application/json') == 1
       res = loadjson(content);
       result = getfield(res, name);
     else
       result = content;
     end
   else
     warn = ['Access to resource ' resource ' returned HTTP error ' retcode];
     warning(warn);
     result = NaN;
   end
end
