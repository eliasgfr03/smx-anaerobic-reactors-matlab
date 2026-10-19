function summary=finalize_pl_own_v1(b)
%FINALIZE_PL_OWN_V1 Native lower-envelope/deviance finalization, no refitting.
% Uses only own explicit anchors, origins and declared profile/reuse mappings.
runs=jwpe_read_native_pl_v1(b);
held=cellfun(@(r)startsWith(r.status,'HOLD') || startsWith(r.status,'STOP'),runs);
if any(held)
    summary=struct('status','HOLD_RETAINED','nativeHolds',{runs(held)}, ...
        'confidenceIntervalsComputed',false,'automaticClosure',false);
    folder=jwpe_own_output_v1(b.folder);
    m1_atomic_v1(fullfile(folder,'summary.mat'),summary,'mat',false);
    jwpe_closed_source('close',folder,{'summary.mat'});return
end
ids=cellfun(@(r)string(r.caseId),runs);
assert(all(ismember(ids,string(b.requiredOrigins))) && ...
    numel(unique(string(b.requiredOrigins)))==numel(b.requiredOrigins), ...
    'JWPE:Own:Catalogue','Undeclared origin or duplicate required origin.');
complete=all(ismember(string(b.requiredOrigins),ids));
anchorIndex=find(ids==string(b.anchorCaseId));
assert(isscalar(anchorIndex),'JWPE:Own:Anchor','Explicit own-run anchor required.');
anchor=runs{anchorIndex};baseline=anchor.nll;
minimum=min(cellfun(@(r)r.nll,runs));
if strcmp(b.model,'M0')
    assert(minimum>=baseline-5e-4,'JWPE:Own:Anchor','ANCHOR_CHALLENGE: no automatic promotion.');
else
    baseline=minimum;
end
closureRequired=false;
if strcmp(b.model,'M1_FIXED')
    closures=cellfun(@(r)strcmp(r.role,'FIXED_KD_CLOSURE'),runs);
    assert(nnz(closures)<=1,'JWPE:Own:Closure','At most one explicit closure per reactor.');
    closureRequired=baseline<anchor.nll-5e-4 && ~any(closures);
end
if strcmp(b.model,'M0')
    names=["Kd","kb","krev","kG","tinf","Ai"];
else
    names=["Kd","kb","kG","tinf","Ai"];
end
points=b.points;records=cell(numel(points),1);
for k=1:numel(points)
    p=points(k);j=find(ids==string(p.caseId));
    assert(isscalar(j),'JWPE:Own:Coverage','Declared profile point lacks its own origin.');
    r=runs{j};idx=find(names==string(p.profile));
    coordinateMatches=isscalar(idx);
    if coordinateMatches
        if strcmp(b.model,'M0')
            coordinateMatches=abs(r.theta(idx)-p.coordinate)<=1e-12;
        else
            coordinateMatches=r.theta(idx)==p.coordinate;
        end
    end
    assert(coordinateMatches, ...
        'JWPE:Own:Coordinate','Native profile coordinate or explicit reuse changed.');
    records{k}=struct('reactor',b.reactor,'profile',p.profile,'caseId',p.caseId, ...
        'theta',r.theta,'nll',r.nll,'coordinate',r.theta(idx), ...
        'deviance',2*(r.nll-baseline),'anchorNLL',baseline, ...
        'provenance','EXPLICIT_OWN_RECHECKED_ORIGIN');
end
envelopes=struct();brackets=struct();
if strcmp(b.model,'M0')
    profiles=unique(string({points.profile}),'stable');
    for profile=profiles
        choose=cellfun(@(r)strcmp(r.profile,profile),records);
        q=records(choose);
        raw=table(string(cellfun(@(r)r.caseId,q,'UniformOutput',false)), ...
            cellfun(@(r)r.coordinate,q),cellfun(@(r)r.nll,q), ...
            'VariableNames',{'CaseID','FixedValue','NLL'});
        raw=[table("own_anchor",anchor.theta(names==profile),anchor.nll, ...
            'VariableNames',raw.Properties.VariableNames);raw]; %#ok<AGROW>
        envelope=jwpe_pl_m0_lower_envelope(raw,anchor.nll);
        cross=find((envelope.Deviance(1:end-1)<b.D95) ~= ...
            (envelope.Deviance(2:end)<b.D95));
        envelopes.(char(profile))=envelope;
        brackets.(char(profile))=[envelope.FixedValue(cross),envelope.FixedValue(cross+1)];
    end
end
status='OWN_PROFILES_CONSOLIDATED_REVIEW_REQUIRED';
if ~complete,status='PARTIAL_GRID';end
if closureRequired,status='HOLD_CLOSURE_REQUIRED';end
summary=struct('status',status,'model',b.model,'reactor',b.reactor, ...
    'records',{records},'envelopes',envelopes,'thresholdBrackets',brackets, ...
    'D95',b.D95,'completeDeclaredCatalogue',complete,'closureRequired',closureRequired, ...
    'conditional',strcmp(b.model,'M1_FIXED'),'newForwards',0, ...
    'automaticClosure',false,'confidenceIntervalsComputed',false,'posteriorPooling',false);
folder=jwpe_own_output_v1(b.folder);
m1_atomic_v1(fullfile(folder,'summary.mat'),summary,'mat',false);
jwpe_closed_source('close',folder,{'summary.mat'});
end
