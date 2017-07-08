close all; clear;


addpath('~/Desktop/APIs/Matlab');
host = 'http://10.1.3.130:4950';
laser = '/perception/laser/0/distances?range=-90:90:1';

gr1.name = 'group1';
gr1.resources{1} = '/motion/vel';
gr1.resources{2} = '/motion/pose';
gr1.resources{3} = '/perception/laser/0/distances?range=-90:90:1';
gr1.resources{4} = '/motion/vel2';


b = 165;

P_hist = [];
P_hist_read = [];
P_feat_hist = [];
R_t = [25 0 0 ; 0 25 0 ; 0 0 (0.5*pi/180)^2];
Q_t = [1 0; 0 (0.5*pi/180)^2];
Sigma = [ 0 0 0; 0 0 0; 0 0 0];
Xi_t = [0;0;0];
Ks = 0.05;

http_init('');
http_delete([host '/group/group1']);
g1 = http_post([host '/group'],gr1);
g1 = [host '/group/group1'];


P.x = 2340;
P.y = 1600;
P.th = 0;

Delta_t = 0.5;
map;

http_put([host '/motion/pose'],P);
leitura = http_get(g1);
Pose_R = [leitura{2}.pose.x; leitura{2}.pose.y; NormAngle(leitura{2}.pose.th*pi/180)];
Xt = [ 0; 0; 0 ];
Xt(1) = Pose_R(1);
Xt(2) = Pose_R(2);
Xt(3) = Pose_R(3);
tic();
while true
  leitura = http_get(g1);
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
  %Delta_t = toc();
  gap = toc();
  sleep(abs(Delta_t-gap));
  tic();
  leitura = http_get(g1);
  Pose_R = [leitura{2}.pose.x; leitura{2}.pose.y; NormAngle(leitura{2}.pose.th*pi/180)];
  Xt(1) = Pose_R(1);
  Xt(2) = Pose_R(2);
  Xt(3) = Pose_R(3);
  f = FeatureDetection(leitura{3}.distances,[-90 90 1]);
  if length(f(:,1)) > 0 
    for k=1:length(f(:,1))
      Map_aux = [(Pose_R(1)) ; (Pose_R(2))] + [(f(k,1)*cos(f(k,2)+Pose_R(3))) ; (f(k,1)*sin(f(k,2)+Pose_R(3)))];
      found = false;
      if length(Xt) > 3
        for j=4:2:length(Xt)
          if sqrt((Xt(j)-Map_aux(1))^2+((Xt(j+1)-Map_aux(2))^2)) <= 250 # Euclidian distance test
            %Mesma feature encontrada
            found = true;
            %Montando a Matriz Fxi
            Fxi = zeros(5,length(Xt));
            Fxi(1,1) = 1; Fxi(2,2) = 1; Fxi(3,3) = 1;
            Fxi(4,j) = 1; Fxi(5,j+1) = 1;
            %verificando qual o indice
            xi = Xt(j);
            yi = Xt(j+1);
          endif
        endfor
      endif
      if found == false
        %Adicionando uma nova feature
        if Delta_th == 0
        len = length(Xt);
        Xt(len+1) = Map_aux(1);
        Xt(len+2) = Map_aux(2);
        xi = Xt(len+1);
        yi = Xt(len+2);
        Sigma = resize(Sigma, len+2);
        Sigma(len+1,len+1) = Q_t(1,1);
        Sigma(len+2,len+2) = Q_t(1,1);        
        endif
      else 
        % Atualizando o vetor de estados e o Sigma
        d = [xi-Xt(1); yi-Xt(2)];
        q = d'*d;
        Ht = [];
        Ht = (1/q)*[-1*sqrt(q)*d(1) -1*sqrt(q)*d(2) 0 sqrt(q)*d(1) sqrt(q)*d(2); d(2) -1*d(1) -1*q -1*d(2) d(1)]*Fxi;
        Kt = Sigma*Ht'*inv((Ht*Sigma*Ht')+Q_t);
        Zt = [sqrt(q); NormAngle(NormAngle(atan2(d(2),d(1)))-Xt(3))];
        Zit = [f(k,1);NormAngle(f(k,2))];
        INOVA = Zit - Zt;
        INOVA(2) = NormAngle(INOVA(2));
        Xt = Xt + Kt*INOVA;
        Xt(3) = NormAngle(Xt(3));
        for i=4:2:length(Xt)
          P_feat_hist = [P_feat_hist; Xt(i) Xt(i+1)];
        endfor
        fflush(stdout);
        Sigma = (eye(length(Xt)) - (Kt*Ht))*Sigma;
      endif
    endfor
    # Pose Update
    Pose_K = [Xt(1);Xt(2);Xt(3)];
    Pose_K
    Pose_R
    DeltaP = Pose_K - Pose_R;
    dp.x = DeltaP(1);
    dp.y = DeltaP(2);
    dp.th = NormAngle(DeltaP(3));
    dp.th = dp.th*180/pi;
    dp
    if Delta_th == 0 && abs(dp.th) < 5 %&& abs(dp.x) < 50 && abs(dp.y) < 50
      disp('Atualizando');
      http_post([host '/motion/pose'],dp);
    endif
    P_hist = [P_hist; Xt(1) Xt(2)];
    P_hist_read = [P_hist_read; Pose_R(1) Pose_R(2)];
    figure(1);
    plot(L.x(:) , L.y(:) , 'ob' , 'linewidth' , 1 , 'markersize' , 10,'color', 'b');
    hold on
    plot(P_hist(:,1) , P_hist(:,2) , 'ob' , 'linewidth' , 2 , 'markersize' , 5,'color', 'g');
    hold on
    plot(P_hist_read(:,1) , P_hist_read(:,2) , 'ob' , 'linewidth' , 2 , 'markersize' , 5,'color', 'r');
    hold on
    if length(P_feat_hist) > 0
      plot(P_feat_hist(:,1) , P_feat_hist(:,2), 'xb' , 'linewidth' , 1 , 'markersize' , 10,'color','r');
    end
    hold off
    refresh();
    fflush(stdout);
   endif
endwhile
