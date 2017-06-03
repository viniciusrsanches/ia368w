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

%
% Computa a distancia lida em uma direcao para um sensor laser simulado
% Parametros:
% mapa: matriz Nx7 onde cada linha contem uma reta do mapa
% pose do robo (x, y, th) com th em radianos
% angulo: angulo do raio emitido no referencial do robo em radianos
%
function result = laser_part(mapa, pose, angulo)

% cada linha do mapa contem 7 parametros
% - pontos x,y de inicio da reta
% - pontos x,y de fim da reta
% - coeficientes da reta a, b, c (ax + b = c)

% reta do raio laser
teta = mod(pose.th + angulo, 2*pi);
if abs(teta) == pi/2 || abs(teta) == 3*pi/2
   a = 1;
   b = 0;
   c = pose.x;
else
   a = tan(teta);
   b = -1;
   c = a*pose.x - pose.y;
end

Pontos = [];

for i=1:rows(mapa)
   % computa interseccao do raio com a reta
   % se sao paralelas, continue
   if a == 0 && mapa(i, 5) == 0
     continue;
   elseif b == 0 && mapa(i, 6) == 0
     continue;
   elseif b != 0 && mapa(i, 6) != 0 && abs(a/b - mapa(i, 5)/mapa(i, 6)) < 1.0e-8
     continue;
   end
   A = [mapa(i, 5) mapa(i, 6); a b];
   B = [mapa(i, 7); c];
   p = A\B;

   dist = (p(1)-pose.x)^2 + (p(2)-pose.y)^2;

   % verifique se as coordenadas do ponto estao fora do segmento do mapa
   Xmax = max(mapa(i, 1), mapa(i, 3));
   Xmin = min(mapa(i, 1), mapa(i, 3));
   Ymax = max(mapa(i, 2), mapa(i, 4));
   Ymin = min(mapa(i, 2), mapa(i, 4));
   if p(1) < Xmin || p(1) > Xmax || p(2) < Ymin || p(2) > Ymax
     continue;
   end

   % verifique se o ponto esta no quadrante correto
   if teta >= 0 && teta <= pi/2 && p(1) >= pose.x && p(2) >= pose.y 
     Pontos = [Pontos; p(1) p(2) dist];
   elseif teta >= pi/2 && teta <= pi && p(1) <= pose.x && p(2) >= pose.y
     Pontos = [Pontos; p(1) p(2) dist];
   elseif teta >= pi && teta <= 3*pi/2 && p(1) <= pose.x && p(2) <= pose.y
     Pontos = [Pontos; p(1) p(2) dist];
   elseif teta >= 3*pi/2 && teta <= 2*pi && p(1) >= pose.x && p(2) <= pose.y 
     Pontos = [Pontos; p(1) p(2) dist];
   end
endfor

if rows(Pontos) == 0   % nenhum ponto encontrado !?!?
   result = 1000000;
   return;
end

% retorna o ponto de menor distância e simula erro do sensor
P = sortrows(Pontos, 3);

result = sqrt((P(1,1) - pose.x)^2 + (P(1,2) - pose.y)^2); %+ (sigma^2)*randn;
end

