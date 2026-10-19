function initial = jwpe_pl_m0_initial(saved,nvar)
%JWPE_PL_M0_INITIAL Exact normalized source starts, never rounded/projection Fval.
x=double(saved.X);
assert(ismatrix(x) && size(x,2)==nvar && size(x,1)>0 && all(isfinite(x(:))) ...
    && all(x(:)>=-1e-12 & x(:)<=1+1e-12),'JWPE:PL:Initial','Malformed exact initial points.');
if isempty(saved.Fval)
    initial=x;
else
    f=double(saved.Fval(:));
    assert(numel(f)==size(x,1) && all(isfinite(f)), ...
        'JWPE:PL:Initial','Invalid exact known Fval.');
    initial=struct('X',x,'Fval',f);
    if ~isempty(saved.Ineq)
        c=double(saved.Ineq);
        assert(size(c,1)==size(x,1) && all(isfinite(c(:))), ...
            'JWPE:PL:Initial','Invalid exact initial constraints.');
        initial.Ineq=c;
    end
end
end
