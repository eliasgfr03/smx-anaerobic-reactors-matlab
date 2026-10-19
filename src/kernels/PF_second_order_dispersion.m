function d2Cdz2 = PF_second_order_dispersion(C,dz)
%PF_SECOND_ORDER_DISPERSION Accepted three-point centered second derivative.
%
% Boundary entries are intentionally left at zero because boundary conditions
% are imposed explicitly by the reduced-state formulation.

C = C(:);
d2Cdz2 = zeros(size(C));
d2Cdz2(2:end-1) = (C(1:end-2)-2*C(2:end-1)+C(3:end))/(dz^2);
end
