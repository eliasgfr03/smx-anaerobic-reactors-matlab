function S = PF_jpattern_reduced(settings)
%PF_JPATTERN_REDUCED Conservative Jacobian sparsity pattern for PF v3.
%
% ACTIVE PF v3 state:
%   y = [SMX interior nodes 2:(n-1);
%        TP  interior nodes 2:(n-1)]
%
% With n=71, ni=n-2=69 and the reduced ODE has 138 states.
%
% For an interior physical node i, the accepted positive-flow MINMOD
% derivative can depend on concentrations from i-2 through i+1.
% The centered second-order dispersion uses i-1 through i+1 and is therefore
% a subset of that transport stencil. The reversible reaction additionally
% couples SMX and TP at the same node.
%
% The pattern is deliberately CONSERVATIVE: a 1 means that the derivative
% MAY be nonzero. Extra structural ones are safe; missing a possible nonzero
% would be unsafe. No analytical Jacobian values are supplied: ode15s still
% evaluates the Jacobian numerically and uses this pattern only to exploit
% sparsity.

n = settings.node_count;
ni = n-2;

assert(n>=5,'PF_jpattern_reduced requires at least 5 spatial nodes.');

sameSpecies = spalloc(ni,ni,4*ni);
for j = 1:ni
    cols = max(1,j-2):min(ni,j+1);
    sameSpecies(j,cols) = 1; %#ok<SPRIX>
end

crossSpecies = speye(ni);

S = spones([sameSpecies, crossSpecies; ...
            crossSpecies, sameSpecies]);

assert(isequal(size(S),[2*ni 2*ni]),'Unexpected JPattern size.');
end
