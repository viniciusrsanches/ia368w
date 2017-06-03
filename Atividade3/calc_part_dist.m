function result = calc_part_dist(particles)
  result = [];
  map;
  for i=1:length(particles)
    pose.x = particles(i,1);
    pose.y = particles(i,2);
    pose.th = NormAngle(particles(i,3));
    aux = [];
    for ang=-90:5:90
      angulo = NormAngle((ang*pi)/180);
      dist_ = laser_part(mapa,pose,angulo);
      aux = [aux dist_];
    endfor
    result = [result; aux];
  endfor
endfunction