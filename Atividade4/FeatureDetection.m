%
%   Copyright (C) 2014 Eleri Cardozo
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

% function result = FeatureDetection(distances, range)
% 
% argumentos:
% distances: /perception/laser/n/distances?range=min:max:incr
% range: [min max incr] in degrees
% 

function result = FeatureDetection(distances, range)


% Split and Merge
Points = SplitAndMerge(distances, range);
if length(Points) < 3   % unica reta ?
  printf("Nenhuma feature detectada\n");
  fflush(stdout);
  result = [];
  return;
end

% Landmarks detectados no momento atual pelo sensor (com erro)
len = length(Points);
Features = [];
for i = 1:(len/2-1)
   if Points(3, i*2-1) == 1   % despreza retas com apenas 2 pontos
	  continue;
   end
   x = Points(1, i*2);
   y = Points(2, i*2);
   r = sqrt(x^2 + y^2); % [mm]
   b = atan2(y, x); % [rad]
   b = mod(b, 2*pi);
   if b > pi
     b = b - 2*pi;
   elseif b < -pi
     b = 2*pi + b;
  end
 Features = [Features; r b];
endfor
result = Features;
end
