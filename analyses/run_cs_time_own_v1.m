function result=run_cs_time_own_v1(b)
assert(nargin==1 && isequal(b.executeScientific,true),'JWPE:Public:ScienceHeld','CS scenario computation held.');
folder=jwpe_own_output_v1(b.folder);cs=b.chainsCS;pf=b.chainsPF;
result=cs_tse_full_core_v1(cs,pf,b.config);
m1_atomic_v1(fullfile(folder,'result.mat'),result,'mat',false);
end
