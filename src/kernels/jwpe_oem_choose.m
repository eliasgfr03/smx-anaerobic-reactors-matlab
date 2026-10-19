function selected = jwpe_oem_choose(runs,cfg)
%JWPE_OEM_CHOOSE Source endpoint/quality selection; no scientific evaluation.
assert(numel(runs)==cfg.multistart.numberOfStarts,'JWPE:OEM:Incomplete', ...
    'Exactly four completed starts are required.');
valid = find([runs.qualityPass]);
if isempty(valid)
    finite = find(isfinite([runs.nll]));
    assert(~isempty(finite),'JWPE:OEM:Incomplete','No finite endpoint.');
    [~,j] = min([runs(finite).nll]);
    index = finite(j);
    stability = 'NO_VALID_RUN';
    agree = 0;
else
    [~,j] = min([runs(valid).nll]);
    index = valid(j);
    agree = nnz([runs(valid).nll]<=runs(index).nll+ ...
        cfg.quality.multistartAgreementNLL);
    if agree>=cfg.quality.minimumAgreeingStarts
        stability = 'STABLE';
    else
        stability = 'REVIEW_REQUIRED';
    end
end
selected = struct('best',runs(index),'bestIndex',index, ...
    'stability',stability,'agreeingStarts',agree);
end
