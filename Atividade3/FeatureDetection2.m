%
%   Copyright (C) 2014 Leonardo Rocha Olivi, Eleri Cardozo
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

% function result = FeatureDetection(dists, angles, L, Pose)
% 
% argumentos:
% dists: vetor de distancias obtido com um laser scan
% angles[] (int): [min max step]
% L (landmarks): L.x e L.y [mm]
% Pose: pose com th em rad
% 

function result = FeatureDetection2(dists, angles, L, Pose)

% --------------------------------------
epsRange = 75;
epsBearing = 5*pi/180;
% ---------------------------------------

% Passo 1 - Split and Merge

Points = SplitAndMerge(dists, angles, L, Pose);
if length(Points) < 3   % unica reta ?
  printf("Nenhuma feature detectada\n");
  fflush(stdout);
  return;
end

% Passo 2 - Calculo da MAXIMA VEROSSIMILHANCA

% As features dos landmarks verdadeiros relativas a posicao atual:
Z.range   = sqrt((L.x - Pose.x).^2 + (L.y -  Pose.y).^2); % [mm]
Z.bearing = atan2(L.y - Pose.y , L.x - Pose.x) - Pose.th; % [rad]

% Landmarks detectados no momento atual pelo sensor (com erro)
len = length(Points);
for i = 1:(len/2-1)
   l.x(i) = Points(1, i*2);
   l.y(i) = Points(2, i*2);
endfor

% Features atuais
z.range = sqrt((l.x - Pose.x).^2 + (l.y - Pose.y).^2); % [mm]
z.bearing = atan2(l.y - Pose.y, l.x - Pose.x) - Pose.th; % [rad]

k = 1;
Features = [];
for i = 1:length(z.range)
   for j = 1:length(Z.range)
      deltaRange = abs(z.range(i) - Z.range(j));
      deltaBearing = abs(z.bearing(i) - Z.bearing(j));
        if deltaRange < epsRange && deltaBearing < epsBearing
          Features = [Features; l.x(i) l.y(i) L.x(j) L.y(j) deltaBearing];
          Corresp.feature(k) = j;
        end
    end
end

figure(2);
plot(L.x , L.y , 'ob' , 'linewidth' , 2 , 'markersize' , 10);
hold on
plot(l.x , l.y , 'xr' , 'linewidth' , 2 , 'markersize' , 10);
hold off
xlabel('x');
ylabel('y');
axis equal; grid on;


result = Features;
fflush(stdout);
end
