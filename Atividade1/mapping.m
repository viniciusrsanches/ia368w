function mapping()
  
  addpath('~/Desktop/APIs/Matlab');
  host = 'http://10.1.3.130:4950';
  laser = '/perception/laser/0/distances?range=-90:90:10';
  
  gr.name = 'group1';
  gr.resources{1} = '/motion/vel';
  gr.resources{2} = '/motion/pose';
  gr.resources{3} = '/perception/laser/0/distances?range=-90:90:10';
  % dados do laser
  precisao = 50;  % mm
  passo = 1*pi/180;   % rad

%  sigma = [0.5 0 ; 0 0.05];   % altera o shape da curva - erro muito grande - sonar
  sigma = [0.05 0 ; 0 0.005];   % altera o shape da curva - erro menor - laser
%  sigma = [0.005 0 ; 0 0.005];   % altera o shape da curva - erro menor - laser
  invSigma = inv(sigma);
  Pmin = 0.2;
  K = 0.000780;   % altera o maximo da curva (0.7-0.8)
 % K = 0.0000780;   % altera o maximo da curva (0.7-0.8)
%  K = 0.07;   % altera o maximo da curva
  % tamanho da celula
  tamCel = 100;     % mm
  % numero de celulas
  numCelX = 60;     % 10 x 10 m
  numCelY = 45;
  x = linspace(1, numCelX, numCelX);  % X
  y = linspace(1, numCelY, numCelY);  % Y
  [xx, yy] = meshgrid(x, y);
  max = 0;
  http_init('');
  http_delete([host '/group/group1'])
  g1 = http_post([host '/group'],gr)
  g1 = [host '/group/group1'];
  p1.x = 2340;
  p1.y = 1600;
  p1.th = 0;
  http_put([host '/motion/pose'],p1);
  
  % mapa
  mapa = zeros(numCelX, numCelY);

  %pose do robo
  %px = 2340;
  %py = 1600;
  %pth = 0*pi/180;
  %move_delta = 180;
  shift_x = 600;
  shift_y = 600;
  z = zeros(length(x), length(y));
  keep_going = true;
  thl = [];
  for i=1:(((90-(-90))/10)+1)
    thl =[thl ((((i-1)*10-90)*pi/180))];
  endfor
  while keep_going == true,
    %range = 2000;
    %fi = 20*pi/180;
   % mu = [range fi];
    % leitura do laser
    %http_delete('http://127.0.0.1:4950/group/group1');
    %g1 = http_post('http://127.0.0.1:4950/group', gr)
    ranges_lidas = [];
    %thl = [];
    leitura = http_get(g1);
    pose = leitura{2}.pose;
    %pose = http_get([host '/motion/pose']);
    %ranges_lidas = [ranges_lidas http_get([host laser])];
    px = pose.x+shift_x;
    py = pose.y+shift_y;
    pth = pose.th*pi/180;
    
    ranges_lidas = leitura{3}.distances;

    cont = 0;
    keep_going = false;
    for i=1:length(x)
      % posicao da celula (i,j) no referencial global
      xi = (i-1)*tamCel + tamCel/2;
      for j=1:length(y)        
         yj = (j-1)*tamCel + tamCel/2;
         % raio em relacao ao robo
         r = sqrt((xi-px)^2 + (yj-py)^2);
         % angulo em relacao ao robo
         b = atan2((yj-py), (xi-px)) - pth;
         % diferença em relacao a leitura do sensor
         for k=1:length(ranges_lidas)
           range = ranges_lidas(k);
           fi = thl(k);
           mu = [range fi];
           delta = [r b] - mu;
           P = Pmin;
           if abs(delta(2)) <= 2*passo		
         %  if abs(delta(2)) < 2*passo && abs(delta(1)) < 2*precisao
           if r < mu(1)
            P = Pmin;
           else
            if z(i,j) == 0
              P = 0.5;
            end
           end
         %     end
           delta(1) = delta(1)/1000;   % distancia em metros
           calculo = P + (K/(2*pi*sigma(1,1)*sigma(2,2)) + 0.5-P)*exp(-0.5*delta*invSigma*delta') ;
           if calculo >= z(i,j) && (calculo < 1.0)      
             z(i,j) = calculo; %P + (K/(2*pi*sigma(1,1)*sigma(2,2)) + 0.5-P)*exp(-0.5*delta*invSigma*delta');           
             mapa(i,j) = mapa(i,j) + log(z(i,j)/(1-z(i,j)));
           end

           end
               
             endfor
          if z(i,j) == 0 
           keep_going = true;
          end
          if (i-1 >= 1 && i+1 <= numCelX && j-1 >= 1 && j+1 <= numCelY) && z(i,j) == 0.2 && (z(i,j+1) == 0.5 || z(i,j-1) == 0.5 || z(i+1,j) == 0.5 || z(i-1,j) == 0.5 || z(i+1,j+1) == 0.5 || z(i-1,j-1) == 0.5 || z(i-1, j+1) == 0.5 || z(i+1,j-1) == 0.5)
           keep_going = true;
          end
            if z(i,j) > max
                max = z(i,j);
            end

       end

    end
    max

   figure 1;
   surf(xx,yy,mapa');
   xlabel('X')
   ylabel('Y')
   zlabel('p(x|z-mapa,theta)')
   refresh();
   figure 2;
   surf(xx,yy,z');
   xlabel('X')
   ylabel('Y')
   zlabel('p(x|z,theta)')
   refresh();

  end
 max
endfunction

