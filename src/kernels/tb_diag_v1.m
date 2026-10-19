function result = tb_diag_v1(physicalChains,cfg,label)
%TB_DIAG_V1 Guarded physical-to-legacy adapter for validated diagnostics.

assert(iscell(physicalChains) && numel(physicalChains)==4, ...
    'JWPE:TB:Diagnostics','Exactly four physical chains are required.');
legacy = cell(1,4);
for c=1:4
    physical = physicalChains{c};
    assert(size(physical,2)==7 && all(isfinite(physical),'all') && ...
        all(physical(:,6:7)>0,'all'),'JWPE:TB:Diagnostics', ...
        'Diagnostics require finite physical Stage-1 rows.');
    legacy{c} = tb_xform_v1('physical_to_legacy',physical,cfg);
end
diagCfg = struct('diagnostics',cfg.diagnostics, ...
    'reportNames',cfg.names.physical);
result = mc_diag_v1(legacy,diagCfg,label);
result.adapter = 'PHYSICAL_TO_LEGACY_LOG_SIGMA_ONLY';
result.directSampledZInputProhibited = true;
result.bulkESSPerRow = result.table.BulkESS/result.chainLength;
result.tailESSPerRow = result.table.TailESS/result.chainLength;
end
