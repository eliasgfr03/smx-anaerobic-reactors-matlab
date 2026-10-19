function E = jwpe_pl_m0_lower_envelope(T,anchorNLL)
%JWPE_PL_M0_LOWER_ENVELOPE Exact source v4 grouping and deviance calculation.
assert(istable(T) && height(T)>0 && all(isfinite(T.NLL)) ...
    && all(isfinite(T.FixedValue)),'JWPE:PL:Envelope','Invalid conditional table.');
span=max(T.FixedValue)-min(T.FixedValue);
tol=max(1e-12,1e-11*max(1,span));
T=sortrows(T,{'FixedValue','NLL'});
rows=zeros(0,1);
i=1;
while i<=height(T)
    j=i;
    while j<height(T) && abs(T.FixedValue(j+1)-T.FixedValue(i))<=tol
        j=j+1;
    end
    [~,k]=min(T.NLL(i:j));
    rows(end+1,1)=i+k-1; %#ok<AGROW>
    i=j+1;
end
E=T(rows,:);
E.DeltaNLL=E.NLL-anchorNLL;
E.Deviance=2*E.DeltaNLL;
E=sortrows(E,'FixedValue');
end
