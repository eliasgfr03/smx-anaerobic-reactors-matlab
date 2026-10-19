function theta = jwpe_pl_m0_map(x,caseConfig)
%JWPE_PL_M0_MAP Source native slice or isolated Kd diagnostic mapping.
x=double(x(:).');
assert(numel(x)==numel(caseConfig.lb) && all(isfinite(x)), ...
    'JWPE:PL:Map','Wrong nuisance vector.');
if strcmp(caseConfig.map,'anchor')
    theta=x;
elseif strcmp(caseConfig.map,'native')
    names={'Kd','kb','krev','kG','tinf','Ai'};
    idx=find(strcmp(names,caseConfig.profile));
    theta=jwpe_s04_full_theta_v2(idx,caseConfig.fixedValue,x);
else
    assert(strcmp(caseConfig.map,'transformed') && strcmp(caseConfig.profile,'Kd'), ...
        'JWPE:PL:Map','Unimplemented source map.');
    spec=struct('nvar',numel(x),'names',string(caseConfig.names), ...
        'param',"Kd",'fixedValue',caseConfig.fixedValue);
    theta=plr1_map(x,spec);
end
end
