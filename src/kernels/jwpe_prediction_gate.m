function gate=jwpe_prediction_gate(action,value)
if strcmp(action,'close')
 f=fullfile(value,'prediction.mat');assert(isfile(f));
 gate=struct('folder',value,'predictionSHA256',m1_hash_v1(f,'file'),'responseAccessAllowed',true);
 m1_atomic_v1(fullfile(value,'prediction_receipt.json'),jsonencode(gate),'text',false);
else
 assert(strcmp(action,'require') && isstruct(value) && isfield(value,'folder') && ...
   isfield(value,'predictionSHA256') && value.responseAccessAllowed, ...
   'JWPE:Public:ResponseHeld','A closed prediction gate is required.');
 f=fullfile(value.folder,'prediction.mat');
 assert(isfile(f) && strcmp(m1_hash_v1(f,'file'),value.predictionSHA256), ...
   'JWPE:Public:ResponseHeld','Prediction changed before response access.');gate=value;
end
end
