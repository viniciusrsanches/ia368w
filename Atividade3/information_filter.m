close all; clear;


addpath('~/Desktop/APIs/Matlab');
host = 'http://192.168.0.105:4950';
laser = '/perception/laser/1/distances?range=-90:90:5';

gr.name = 'group1';
gr.resources{1} = '/motion/vel';
gr.resources{2} = '/motion/pose';
gr.resources{3} = '/perception/laser/1/distances?range=-90:90:5';
gr.resources{4} = '/motion/vel2';
% dados do laser
precisao = 50;  % mm
passo = 1*pi/180;   % rad
b = 165;
%  sigma = [0.5 0 ; 0 0.05];   % altera o shape da curva - erro muito grande - sonar
sigma = [0.05 0 ; 0 0.005];   % altera o shape da curva - erro menor - laser
%  sigma = [0.005 0 ; 0 0.005];   % altera o shape da curva - erro menor - laser
sigma_move = [50 0; 0 0.035];


R_t = [100 0 0 ; 0 100 0 ; 0 0 0.005];
Q_t = [100 0; 0 0.005];
Omega_t = [ 10^8 0 0; 0 10^8 0 ; 0 0 10^8];
Xi_t = [0;0;0;];

http_init('');
http_delete([host '/group/group1']);
g1 = http_post([host '/group'],gr);
g1 = [host '/group/group1'];

map;

while true
  Delta_t = 3;
  leitura = http_get(g1);
  x_inicial = leitura{2}.pose.x;
  y_inicial = leitura{2}.pose.y;
  th_inicial = leitura{2}.pose.th;
  th_inicial = NormAngle(th_inicial*pi/180);
  mu_t = [x_inicial; y_inicial; th_inicial];
  Delta_S = ((leitura{4}.vel2.right+leitura{4}.vel2.left)*Delta_t)/2;
  Delta_th = ((leitura{4}.vel2.right+leitura{4}.vel2.left)*Delta_t)/2*b;
  G_t = [ 1 0 -1*Delta_S*sin(mu_t(3)+(Delta_th/2)) ; 0 1 Delta_S*cos(mu_t(3)+(Delta_th/2)); 0 0 1];
  Omega_t = inv(G_t*inv(Omega_t)*(G_t')+R_t);
  Xi_t = Omega_t*mu_t;
  f = FeatureDetection2(leitura{3}.distances,[-90 90 5],L,leitura{2}.pose);
  for k=1:length(f(:,1))
    de = [ (f(k,3)-mu_t(1,1)) (f(k,4)-mu_t(2,1))];
    q = de*de';
    dx = de(1);
    dy = de(2);
    H_t = (1/q)*[-dx*sqrt(q) dy*sqrt(q) 0 ; dy -dx -q];
    lamb = [(f(k,1)-mu_t(1,1)) (f(k,2)-mu_t(2,1))];
    r = lamb*lamb';
    rx = lamb(1);
    ry = lamb(2);
    z_t = [ sqrt(r); atan2(dy,dx) - mu_t(3,1)];
    h_t = [ sqrt(q); atan2(dy,dx) - mu_t(3,1)];
    Omega_t = Omega_t + H_t'*inv(Q_t)*H_t;
    Xi_t = Xi_t + H_t'*inv(Q_t)*[z_t-h_t + H_t*mu_t];
  endfor
  mu_t = inv(Omega_t) * Xi_t;
  mu_t(3,1) = NormAngle(mu_t(3,1));
endwhile
