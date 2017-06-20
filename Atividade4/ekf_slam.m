close all; clear;


addpath('~/Desktop/APIs/Matlab');
host = 'http://192.168.0.105:4950';
laser = '/perception/laser/1/distances?range=-90:90:1';

gr1.name = 'group1';
gr1.resources{1} = '/motion/vel';
gr1.resources{2} = '/motion/pose';
gr1.resources{3} = '/perception/laser/1/distances?range=-90:90:1';
gr1.resources{4} = '/motion/vel2';


b = 165;



R_t = [25 0 0 ; 0 25 0 ; 0 0 (0.5*pi/180)^2];
Q_t = [1 0; 0 (0.5*pi/180)^2];
Sigma = [ 0 0 0; 0 0 0; 0 0 0];
Xi_t = [0;0;0;];
Ks = 0.05;

http_init('');
http_delete([host '/group/group1']);
g1 = http_post([host '/group'],gr1);
g1 = [host '/group/group1'];

Delta_t = 1;
P.x = 2340;
P.y = 1600;
P.th = 0;

Delta_t = 3;
Map = [];

http_put([host '/motion/pose'],P);
leitura = http_get(g1);
Pose_R = [leitura{2}.pose.x; leitura{2}.pose.y; NormAngle(leitura{2}.pose.th*pi/180)];
Xt = [ 0 0 0 ];
Xt(1) = Pose_R(1);
Xt(2) = Pose_R(2);
Xt(3) = Pose_R(3);
while true
  tic();
  Delta_S = ((leitura{4}.vel2.right+leitura{4}.vel2.left)*(Delta_t))/2;
  Delta_th = ((leitura{4}.vel2.right-leitura{4}.vel2.left)*(Delta_t))/2*b;
  G_t = [ 1 0 -1*Delta_S*sin(Pose_R(3)+(Delta_th/2)) ; 0 1 Delta_S*cos(Pose_R(3)+(Delta_th/2)); 0 0 1];   
  V1 = 0.5*cos(Pose_R(3)+(Delta_th/2)) - (Delta_S/4*b)*sin(Pose_R(3)+(Delta_th/2));
  V2 = 0.5*cos(Pose_R(3)+(Delta_th/2)) + (Delta_S/4*b)*sin(Pose_R(3)+(Delta_th/2));
  V3 = 0.5*sin(Pose_R(3)+(Delta_th/2)) + (Delta_S/4*b)*cos(Pose_R(3)+(Delta_th/2));
  V4 = 0.5*sin(Pose_R(3)+(Delta_th/2)) - (Delta_S/4*b)*cos(Pose_R(3)+(Delta_th/2));
  V_t = [V1 V2; V3 V4; (1/2*b) (-1/2*b)];
  Sigma_dt = [Ks*abs(leitura{4}.vel2.right*Delta_t) 0; 0 Ks*abs(leitura{4}.vel2.left*Delta_t)];
  Sigma(1:3,1:3) = (G_t* Sigma(1:3,1:3)*G_t') + (V_t* Sigma_dt *V_t') + R_t;  
  pause(Delta_t);
  leitura = http_get(g1);
  Pose_R = [leitura{2}.pose.x; leitura{2}.pose.y; NormAngle(leitura{2}.pose.th*pi/180)];
  Xt(1) = Pose_R(1);
  Xt(2) = Pose_R(2);
  Xt(3) = Pose_R(3);
  f = FeatureDetection(leitura{3}.distances,[-90 90 1]);
  for k=1:length(f(:,1))
    Map_aux = [(Pose_R(1)) ; (Pose_R(2))] + [(f(k,1)*cos(f(k,2)+Pose_R(3))) ; (f(k,1)*sin(f(k,2)+Pose_R(3)))];
    found = false;
    if length(Xt) > 3
      for j=1:2:length(Map(:,1))
        if sqrt((Map(j,1)-Map_aux(1))^2+((Map(j,2)-Map_aux(2))^2)) <= 200 # Euclidian distance test
          found = true;
          Map(j,1) = Map_aux(1);
          Map(j,2) = Map_aux(2);
          Xt(3+j) = Map_aux(1);
          Xt(3+j+1) = Map_aux(2);
          Fxi = zeros(5,length(Xt));
          Fxi(1,1) = 1; Fxi(2,2) = 1; Fxi(3,3) = 1;
          Fxi(4,3+j) = 1; Fxi(5,3+j+1) = 1;

        endif
      endfor
    endif
    if found == false
      Map = [Map; Map_aux'];
      len = length(Xt);
      Xt = resize(Xt, len+2);
      Xt(len+1) = Map_aux(1);
      Xt(len+2) = Map_aux(2);
      Sigma = resize(Sigma, len+2);
      Sigma(len+1,len+1) = Q_t(1,1);
      Sigma(len+2,len+2) = Q_t(1,1);
      Fxi = zeros(5,length(Xt));
      Fxi(1,1) = 1; Fxi(2,2) = 1; Fxi(3,3) = 1;
      Fxi(4,len+1) = 1; Fxi(5,len+2) = 1;
    endif
    d = [abs(Map_aux(1)-Xt(1)); abs(Map_aux(2)-Xt(2))];
    q = d'*d;
    Ht = (1/q)*[-1*sqrt(q*d(1)) -1*sqrt(q*d(2)) 0 sqrt(q*d(1)) sqrt(q*d(2)); d(2) -1*d(1) -1*q -1*d(2) d(1)]*Fxi;
    Kt = Sigma*Ht'*inv((Ht*Sigma*Ht')+Q_t);
    Zt = [sqrt(q); atan2(d(2),d(1))-Xt(3)];
    Zit = [f(k,1);f(k,2)];
    INOVA = Zit - Zt;
    Xt = Xt + Kt*INOVA;
    Sigma = (eye(length(Xt)) - (Kt*Ht))*Sigma;
  endfor
  # Pose Update
  Pose_K = [Xt(1);Xt(2);Xt(3)];
  DeltaP = Pose_K - Pose_R;
  dp.x = DeltaP(1);
  dp.y = DeltaP(2);
  dp.th = NormAngle(DeltaP(3)*180/pi);
  dp
  http_post([host '/motion/pose'],dp);
  fflush(stdout);
  #refresh();
  #gap = toc();
  #pause(abs(Delta_t-gap));
endwhile
