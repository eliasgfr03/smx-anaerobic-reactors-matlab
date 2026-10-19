function data=prepare_gsa_own_v1(cfg,reactor)
%PREPARE_GSA_OWN_V1 Same Monte Carlo transform/map with explicit own ranges.
assert(ismember(string(cfg.rng.algorithm),["twister","mt19937ar"]) && cfg.rng.cols==6, ...
    'JWPE:Own:GSA','Source MT19937AR six-column design required.');
stream=RandStream('mt19937ar','Seed',cfg.rng.seed);
U=rand(stream,cfg.rng.rows,6);
X=gsa_tri_icdf_v1(U,cfg.(reactor).ranges);
[native,inverse]=gsa_map_v1(X);
assert(all(abs(inverse-X)<=32*eps(max(1,abs(X))),'all'));
data=struct('cfg',cfg,'reactor',reactor,'uniform',U,'sampled',X,'native',native);
end
