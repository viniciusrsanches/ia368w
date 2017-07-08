close all; clear;

num_part_inicial = 500;

addpath('~/Desktop/APIs/Matlab');
host = 'http://10.1.3.215:4950';
laser = '/perception/laser/1/distances?range=-90:90:10';

gr.name = 'group1';
gr.resources{1} = '/motion/vel';
gr.resources{2} = '/motion/pose';
gr.resources{3} = '/perception/laser/1/distances?range=-90:90:10';
% dados do laser
precisao = 50;  % mm
passo = 1*pi/180;   % rad

%  sigma = [0.5 0 ; 0 0.05];   % altera o shape da curva - erro muito grande - sonar
sigma = [0.05 0 ; 0 0.005];   % altera o shape da curva - erro menor - laser
%  sigma = [0.005 0 ; 0 0.005];   % altera o shape da curva - erro menor - laser
sigma_move = [50 0; 0 0.035];

variancia_final = 50;


http_init('');
http_delete([host '/group/group1']);
g1 = http_post([host '/group'],gr);
g1 = [host '/group/group1'];
p1.x = 2340;
p1.y = 1600;
p1.th = 0;
http_put([host '/motion/pose'],p1);

random_particles = gerar_inicial(num_part_inicial);
figure 1
hold on
map;
plot(rot90(mapa(:,1)),rot90(mapa(:,2)),'k','LineWidth',3);
plot(rot90(random_particles(:,1)),rot90(random_particles(:,2)),'.');
leitura = http_get(g1);

x_inicial = leitura{2}.pose.x;
y_inicial = leitura{2}.pose.y;
th_inicial = leitura{2}.pose.th;
th_inicial = NormAngle(th_inicial*pi/180)

variancia_total = 0;
variancia_total = var(random_particles(:,1)) + var(random_particles(:,2));
quantidade = length(random_particles);
while true %variancia_total > variancia_final
  particles_dist = calc_part_dist(random_particles); 
  ranking = ranking_part(particles_dist,leitura{3}.distances,sigma(1,1)*1000);
  if quantidade >= 200
    quantidade = round(quantidade / 2);
  endif
  pose_x = 0;
  pose_y = 0;
  pose_th = 0;
  for j=1:length(random_particles)
    pose_x += random_particles(j,1)*ranking(j);
    pose_y += random_particles(j,2)*ranking(j);
    pose_th += NormAngle(random_particles(j,3)*ranking(j));
  endfor
  
  if variancia_total < variancia_final
    P.x = pose_x;
    P.y = pose_y;
    P.th = pose_th;
    P.th = NormAngle(P.th);
    particle_med = [P.x P.y P.th];
    dists = leitura{3}.distances;   
    landmarks_validos = FeatureDetection2(dists,[-90 90 10],L,P);
    if length(landmarks_validos) > 0
      disp("Land Marks validos encontrados");
      %soma_quadratica_media = 0;
      media_dos_erros = 0;
      variancia_dos_erros = [];
      for i=1:length(landmarks_validos(:,1))
        %soma_quadratica_media += (landmarks_validos(i,1) - landmarks_validos(i,3))^2 + (landmarks_validos(i,2) - landmarks_validos(i,4))^2;
        media_dos_erros += sqrt((landmarks_validos(i,1) - landmarks_validos(i,3))^2 + (landmarks_validos(i,2) - landmarks_validos(i,4))^2);
        variancia_dos_erros = [variancia_dos_erros sqrt((landmarks_validos(i,1) - landmarks_validos(i,3))^2 + (landmarks_validos(i,2) - landmarks_validos(i,4))^2) ];
      endfor
      %soma_quadratica_media /= length(landmarks_validos(:,1));
      media_dos_erros /= length(landmarks_validos(:,1));
      
      %disp(" Soma quadratica media dos erros dos Land Marks: ") , disp(soma_quadratica_media);
      disp(" Media dos erros dos Land Marks: ") , disp(media_dos_erros);
      disp("  Variancia dos erros dos Land Marks: ") , disp(var(variancia_dos_erros));
    else
      disp("Nenhum land mark valido encontrado");
    endif
  endif
  figure 1
  hold off
  plot(rot90(mapa(:,1)),rot90(mapa(:,2)),'k','LineWidth',3);
  hold on
  plot(pose_x,pose_y,'marker','h','color','g','MarkerSize',20);
  plot(leitura{2}.pose.x, leitura{2}.pose.y,'marker','h','color','r','MarkerSize',20);
  plot(rot90(random_particles(:,1)),rot90(random_particles(:,2)),'.');
  leitura = http_get(g1);
  x_final = leitura{2}.pose.x;
  y_final = leitura{2}.pose.y;
  th_final = leitura{2}.pose.th;
  th_final = NormAngle(th_final*pi/180);
  dx = x_final - x_inicial;
  dy = y_final - y_inicial;
  dth = th_final - th_inicial;
  x_inicial = x_final;
  y_inicial = y_final;
  th_inicial = th_final;
  random_particles = reamostragem(random_particles,ranking,quantidade,sigma_move,round(quantidade/2),dx,dy,dth);
  variancia_total = (var(random_particles(:,1)) + var(random_particles(:,2)))/length(random_particles);
  disp("Variancia total: ") , disp (variancia_total);
  disp("Variancia dos pesos: ") , disp(var(ranking));
  fflush(stdout);
  refresh();
endwhile
