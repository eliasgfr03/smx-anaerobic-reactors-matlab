function [hit,value,key]=jwpe_mcmc_memory(action,kind,x,value)
%JWPE_MCMC_MEMORY Exact bounded in-memory memoization, no per-forward files.
% RESET before every independent chain; keys contain the full double bits.
persistent prediction target
if nargin<4,value=[];end
if strcmp(action,'reset')
 prediction=containers.Map('KeyType','char','ValueType','any');
 target=containers.Map('KeyType','char','ValueType','any');
 hit=false;key='';return
end
if strcmp(action,'snapshot')
 hit=false;key='';value=struct('predictionKeys',{keys(prediction)}, ...
  'predictionValues',{values(prediction)},'targetKeys',{keys(target)}, ...
  'targetValues',{values(target)});return
end
if strcmp(action,'restore')
 assert(isstruct(value) && numel(value.predictionKeys)==numel(value.predictionValues) && ...
     numel(value.targetKeys)==numel(value.targetValues),'JWPE:Public:Cache','Invalid snapshot.');
 prediction=containers.Map('KeyType','char','ValueType','any');
 target=containers.Map('KeyType','char','ValueType','any');
 for i=1:numel(value.predictionKeys),prediction(value.predictionKeys{i})=value.predictionValues{i};end
 for i=1:numel(value.targetKeys),target(value.targetKeys{i})=value.targetValues{i};end
 hit=false;key='';return
end
assert(~isempty(prediction) || isa(prediction,'containers.Map'));
key=reshape(num2hex(double(x(:))).',1,[]);
if strcmp(kind,'prediction'),bank=prediction;else,assert(strcmp(kind,'target'));bank=target;end
hit=isKey(bank,key);
if strcmp(action,'probe')
    if hit,value=bank(key);end
elseif strcmp(action,'put')
    if bank.Count>=256,remove(bank,keys(bank));end
    if strcmp(kind,'prediction'),prediction(key)=value;else,target(key)=value;end
else
    error('JWPE:Public:Cache','Unsupported memory action.');
end
end
