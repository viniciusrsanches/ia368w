function result = ranking_part(particles_dist, sensor_dist,sigma)
  result = [];
  w = ones(1,length(particles_dist));
  n_ = 0.0007;
  for i=1:length(particles_dist)
    dist = 0;
    for j=1:length(sensor_dist)
      gauss = (1/(sigma*sqrt(2*pi)))*exp((-1/2)*n_*((particles_dist(i,j)-sensor_dist(j))/sigma)^2);
      w(i) = w(i) * gauss;
      %dist = n_*((particles_dist(i,j) - sensor_dist(j))^2)+dist;
      %if dist > 0;
      %  w(i) = w(i)/dist;
      %endif
      %dist = ((particles_dist(i,j) - sensor_dist(j))^2)+dist;
    endfor
    %w(i) = dist/length(sensor_dist);
  endfor
  soma = sum(w);
  for i=1:length(w)
    w(i) = w(i)/soma;
  endfor
  soma = sum(w);
  result = w;
endfunction