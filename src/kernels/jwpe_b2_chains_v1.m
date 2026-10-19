function chains=jwpe_b2_chains_v1(input,permission)
%JWPE_B2_CHAINS_V1 Explicit four-chain physical reader; no thinning/transforms.
assert(strcmp(input.reactor,permission.reactor) && numel(input.chainFiles)==4 && ...
    isequal(string(input.columns(:)),["Kd";"kb";"kG";"tinf";"Ai";"sigmaA";"sigmaP"]), ...
    'JWPE:B2:Columns','Four separate chains and declared native physical columns required.');
files=string(input.chainFiles(:));assert(numel(unique(files))==4,'JWPE:B2:Chain','Distinct chains required.');
chains=cell(1,4);
assert(isscalar(input.rowsPerChain) && input.rowsPerChain>=4 && ...
    input.rowsPerChain==floor(input.rowsPerChain),'JWPE:B2:Shape','Explicit chain length required.');
for k=1:4
    saved=jwpe_b2_source_v1(char(files(k)),'mat',permission);
    assert(isfield(saved,'physical'),'JWPE:B2:Field','Missing physical array.');
    x=saved.physical;
    assert(isnumeric(x) && isreal(x) && isequal(size(x),[input.rowsPerChain 7]) && ...
        all(isfinite(x),'all') && all(x(:,6:7)>0,'all'), ...
        'JWPE:B2:Shape','Unexpected physical chain content or declared shape.');
    chains{k}=x;
end
end
