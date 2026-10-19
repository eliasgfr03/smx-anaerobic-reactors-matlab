function joint = finalize_capacity_joint_own_v1(b)
csBase=b.csBase;csLog2=b.csLog2;pfBase=b.pfBase;pfLog2=b.pfLog2;
outputFolder=b.folder;
mode=b.mode;
%FINALIZE_CAPACITY_JOINT Manifest-checked reactor results, zero science calls.
% Frozen G1 must match the paired baseline exactly; no parameter pooling.
b={jwpe_capacity_read_run(csBase,'G1_A1',mode),jwpe_capacity_read_run(pfBase,'G1_A1',mode)};
l={jwpe_capacity_read_run(csLog2,'LOG2',mode),jwpe_capacity_read_run(pfLog2,'LOG2',mode)};
reactors={'CS','PF'};
for i=1:2
    assert(strcmp(b{i}.reactor,reactors{i}) && strcmp(l{i}.reactor,reactors{i}) && ...
        strcmp(b{i}.role,l{i}.role),'JWPE:Capacity:Identity','Reactor/role mismatch.');
    assert(isequaln(b{i}.cases.G1.recheck,l{i}.cases.G1.recheck), ...
        'JWPE:Capacity:Reference','LOG2 used a different G1; do not mix comparisons.');
    assert(isequaln(b{i}.identity,l{i}.identity), ...
        'JWPE:Capacity:Identity','Input/config/code identity differs.');
end
folder=jwpe_own_output_v1(outputFolder);
joint=struct('status','TEMPORAL_JOINT_COMPLETE','role',b{1}.role, ...
    'g1_a1',vertcat(b{1}.comparison,b{2}.comparison), ...
    'log2',vertcat(l{1}.comparison,l{2}.comparison),'parameterPooling',false, ...
    'newForwards',0,'newLikelihoodCalls',0,'newOptimizerCalls',0, ...
    'scientificPromotion',false,'sourceFolders',{{csBase,csLog2,pfBase,pfLog2}});
assert(strcmp(b{1}.role,b{2}.role), ...
    'JWPE:Capacity:Identity','Cannot mix published/fabricated/new result roles.');
summary=struct('status',joint.status,'role',joint.role,'reactors',{{'CS','PF'}}, ...
    'parameterPooling',false,'newForwards',0,'newLikelihoodCalls',0, ...
    'newOptimizerCalls',0,'scientificPromotion',false);
joint.testOnly=strcmp(mode,'test');summary.testOnly=joint.testOnly;
if joint.testOnly
    joint.status='TEST_ONLY_TEMPORAL_JOINT_COMPLETE';summary.status=joint.status;
end
names={'result.mat','g1_a1_comparison.csv','log2_comparison.csv','summary.json'};
values={joint,joint.g1_a1,joint.log2,jsonencode(summary)};
kinds={'mat','table','table','text'};
for i=1:4; jwpe_run_write(folder,names{i},values{i},kinds{i},false); end
jwpe_capacity_manifest(folder,names);
end
