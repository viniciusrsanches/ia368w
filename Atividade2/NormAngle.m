function nangle = NormAngle(angle)
  angle = mod(angle,2*pi);
  if angle > pi
    angle = angle - 2*pi;
  elseif angle < -pi
    angle = angle + 2*pi;
  end
  nangle = angle;
endfunction