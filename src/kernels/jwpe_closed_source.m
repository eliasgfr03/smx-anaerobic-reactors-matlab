function receipt=jwpe_closed_source(action,folder,names)
%JWPE_CLOSED_SOURCE Bind complete new-run arrays without importing old endpoints.
if nargin<3,names={};end
file=fullfile(folder,'source_receipt.json');
if strcmp(action,'close')
 assert(~isfile(file),'JWPE:Public:Overwrite','Receipt already exists.');
 rows=struct('name',{},'bytes',{},'sha256',{});
 for i=1:numel(names)
  name=names{i};assert(~contains(name,'..') && ~contains(name,filesep));
  f=fullfile(folder,name);s=dir(f);assert(isscalar(s));
  rows(end+1)=struct('name',name,'bytes',s.bytes,'sha256',m1_hash_v1(f,'file')); %#ok<AGROW>
 end
 receipt=struct('classification','NEW_RUN_CLOSED_SOURCE','files',rows);
 m1_atomic_v1(file,jsonencode(receipt),'text',false);
elseif strcmp(action,'require')
 assert(isfile(file),'JWPE:Public:SourceHeld','Missing closed new-run receipt.');
 receipt=jsondecode(fileread(file));assert(strcmp(receipt.classification,'NEW_RUN_CLOSED_SOURCE'));
 for i=1:numel(receipt.files)
  b=receipt.files(i);assert(~contains(b.name,'..') && ~contains(b.name,filesep));
  f=fullfile(folder,b.name);s=dir(f);
  assert(isscalar(s) && s.bytes==b.bytes && strcmp(m1_hash_v1(f,'file'),b.sha256), ...
      'JWPE:Public:SourceHeld','New-run source changed.');
 end
else
 error('JWPE:Public:SourceHeld','Unknown source action.');
end
end
