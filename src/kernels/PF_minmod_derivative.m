function dCdz = PF_minmod_derivative(C,dz)
%PF_MINMOD_DERIVATIVE Conservative positive-flow TVD/MUSCL MINMOD derivative.
%
% Face reconstruction:
%   C_(i+1/2)^- = C_i + 0.5*slope_i
% where slope_i is the MINMOD-limited concentration increment.

C = C(:);
n = numel(C);
slope = zeros(n,1);

% Interior upwind slopes.
for j = 1:n-2
    a = C(j+1)-C(j);
    b = C(j+2)-C(j+1);
    if a*b > 0
        slope(j+1) = sign(a)*min(abs(a),abs(b));
    end
end

% First face slope.
a = C(2)-C(1);
b = C(3)-C(2);
if a*b > 0
    slope(1) = sign(a)*min(abs(a),abs(b));
end

face = C(1:end-1) + 0.5*slope(1:end-1);
dCdz = zeros(n,1);
dCdz(2:end-1) = (face(2:end)-face(1:end-1))/dz;
end
