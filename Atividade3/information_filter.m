close all; clear;


addpath('~/Desktop/APIs/Matlab');
host = 'http://192.168.0.103:4950';
laser = '/perception/laser/1/distances?range=-90:90:1';

gr1.name = 'group1';
gr1.resources{1} = '/motion/vel';
gr1.resources{2} = '/motion/pose';
gr1.resources{3} = '/perception/laser/1/distances?range=-90:90:1';
gr1.resources{4} = '/motion/vel2';


b = 165;



R_t = [25 0 0 ; 0 25 0 ; 0 0 (2*pi/180)^2];
Q_t = [1 0; 0 (0.5*pi/180)^2];
Omega_t = [ 10^8 0 0; 0 10^8 0 ; 0 0 10^8];
Xi_t = [0;0;0;];
Delta_t = 1;

http_init('');
http_delete([host '/group/group1']);
g1 = http_post([host '/group'],gr1);
g1 = [host '/group/group1'];
time_aux = 0;

map;

while true
  tic();
  leitura = http_get(g1);
  x_inicial = leitura{2}.pose.x;
  y_inicial = leitura{2}.pose.y;
  th_inicial = leitura{2}.pose.th;
  th_inicial = NormAngle(th_inicial*pi/180);
  P.x = x_inicial;
  P.y = y_inicial;
  P.th = th_inicial; 
  #leitura
  mu_t = [x_inicial; y_inicial; th_inicial];
  Delta_S = ((leitura{4}.vel2.right+leitura{4}.vel2.left)*(Delta_t-time_aux))/2;
  Delta_th = ((leitura{4}.vel2.right-leitura{4}.vel2.left)*(Delta_t-time_aux))/2*b;
  G_t = [ 1 0 -1*Delta_S*sin(mu_t(3)+(Delta_th/2)) ; 0 1 Delta_S*cos(mu_t(3)+(Delta_th/2)); 0 0 1];  
  #G_t = [ 1 0 -1 ; 0 1 1; 0 0 1];  
  Omega_t = inv(G_t*inv(Omega_t)*(G_t')+R_t);
  Xi_t = Omega_t*mu_t;
  #Xi_t(3) = NormAngle(Xi_t(3));
  f = FeatureDetection2(leitura{3}.distances,[-90 90 1],L,P);
  if length(f) > 0
    for k=1:length(f(:,1))
      de = [ (f(k,3)-mu_t(1,1)) (f(k,4)-mu_t(2,1))];
      q = de*de';
      dx = de(1);
      dy = de(2);
      H_t = (1/q)*[-dx*sqrt(q) -dy*sqrt(q) 0 ; dy -dx -q];
      lamb = [(f(k,1)-mu_t(1,1)) (f(k,2)-mu_t(2,1))];
      r = lamb*lamb';
      rx = lamb(1);
      ry = lamb(2);
      z_t = [ sqrt(r); atan2(ry,rx) - mu_t(3,1)];
      z_t(2) = NormAngle(z_t(2));
      h_t = [ sqrt(q); atan2(dy,dx) - mu_t(3,1)];
      h_t(2) = NormAngle(h_t(2));
      Omega_t = Omega_t + H_t'*inv(Q_t)*H_t;
      Xi_t = Xi_t + H_t'*inv(Q_t)*[(z_t-h_t) + (H_t*mu_t)];
      #Xi_t(3) = NormAngle(Xi_t(3));
    endfor
    #Xi_t(3) = NormAngle(Xi_t(3));
    mu_t_aux = inv(Omega_t) * Xi_t;
    mu_t_aux(3,1) = NormAngle(mu_t_aux(3,1));
    delta_pose.x = mu_t_aux(1) - mu_t(1);
    delta_pose.y = mu_t_aux(2) - mu_t(2);
    delta_pose.th = NormAngle(mu_t_aux(3) - mu_t(3))*180/pi;
    #delta_pose
    http_post([host '/motion/pose'],delta_pose);
    #mu_t = mu_t_aux;
    time_aux = toc();
    pause(Delta_t-time_aux); 
  #else
    
  endif
endwhile
