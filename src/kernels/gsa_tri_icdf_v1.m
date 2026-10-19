function X = gsa_tri_icdf_v1(U,ranges)
%GSA_TRI_ICDF_V1 Inverse CDF for independent triangular coordinates.
% ranges rows are [lower,mode,upper]; boundary modes are preserved.

U = double(U);
ranges = double(ranges);
assert(size(U,2)==size(ranges,1),'Uniform/range dimension mismatch.');
assert(size(ranges,2)==3,'Ranges must be [lower,mode,upper].');
assert(all(isfinite(U),'all') && all(U>=0 & U<=1,'all'), ...
    'Uniform quantiles must lie in [0,1].');
a = ranges(:,1).'; c = ranges(:,2).'; b = ranges(:,3).';
assert(all(a<=c & c<=b) && all(a<b), ...
    'Every triangular range requires lower <= mode <= upper and lower < upper.');

Fmode = (c-a)./(b-a);
X = zeros(size(U));
for j=1:size(U,2)
    left = U(:,j)<=Fmode(j);
    X(left,j) = a(j) + sqrt(U(left,j).*(b(j)-a(j)).*(c(j)-a(j)));
    right = ~left;
    X(right,j) = b(j) - sqrt((1-U(right,j)).*(b(j)-a(j)).*(b(j)-c(j)));
end
assert(all(X>=a-1e-14 & X<=b+1e-14,'all'), ...
    'Triangular transform escaped an approved range.');
end
