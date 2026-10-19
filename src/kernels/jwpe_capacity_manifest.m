function records = jwpe_capacity_manifest(folder,names)
%JWPE_CAPACITY_MANIFEST Hash already saved payloads; no scientific calls.
records=repmat(struct('File','','Bytes',0,'SHA256',''),numel(names),1);
for i=1:numel(names)
    file=fullfile(folder,names{i}); info=dir(file);
    assert(isscalar(info),'JWPE:Capacity:Manifest','Missing payload.');
    records(i)=struct('File',names{i},'Bytes',info.bytes, ...
        'SHA256',m1_hash_v1(file,'file'));
end
jwpe_run_write(folder,'manifest.csv',struct2table(records),'table',false);
end
