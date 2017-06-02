
function result = gerar_inicial(num_part)
  map;
  result = [];  
  for i=1:num_part
    x_rand = round(rand(1)*MaxX);
    y_rand = round(rand(1)*MaxY);
    th_rand = NormAngle(round((rand* 360))*pi/180);
    result = [ result; [x_rand y_rand th_rand]];
  endfor

endfunction