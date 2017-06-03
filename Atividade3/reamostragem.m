function result = reamostragem(particles, weights, size_ream,sigma, size_sort,dx,dy,dth)
  result =[];
  beta = 0;
  [w_b , i_b] = sort(weights,'descend');
  w_b = w_b(1:size_sort);
  i_b = i_b(1:size_sort);
  [ w_max , i_max ] = max(weights);
  index = round(rand(1)*length(w_b));
  if index == 0
    index = 1;
  endif
  for i=1:size_sort %mantendo os melhores
    result = [result; (particles(i_b(i),1)+dx) (particles(i_b(i),2)+dy) (particles(i_b(i),3)+dth)];
  endfor
  for i=1:size_ream-size_sort %escolhendo novos entre os melhores
    beta = beta + 2*w_max*rand(1);
    while beta > w_b(index)
      beta = beta - w_b(index);
      index = mod((index+1),  length(w_b));
      if index == 0
        index = 1;
      endif
    endwhile
    % insere a perturbação e o deslocamento das dimensões
    result = [ result ; (particles(i_b(index),1)+dx+sigma(1,1)*randn(1)) (particles(i_b(index),2)+dy+sigma(1,1)*randn(1)) (particles(i_b(index),3)+dth+sigma(2,2)*randn(1))];
  endfor
endfunction