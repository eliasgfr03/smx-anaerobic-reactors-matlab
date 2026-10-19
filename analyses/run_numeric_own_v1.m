function result=run_numeric_own_v1(b)
%JWPE_B2_PRODUCE_V1 Six separately held saved-result statistical producers.
% No simulation, target, optimizer, sampler, renderer or implicit fallback.
product=b.product;input=b.numericInput;permission=jwpe_numeric_permission_own_v1(b);
assert(strcmp(input.reactor,permission.reactor),'JWPE:B2:Reactor','Reactor mismatch.');
calls=struct('G1',0,'quantile',0,'Pearson',0,'histcounts',0,'diagnostics',0,'R2flag',0);
switch string(product)
    case "activity"
        assert(permission.G1CallsMax>=500 && permission.activityQuantileCallsMax>=1, ...
            'JWPE:B2:Quota','Activity calls not released.');
        draws=jwpe_b2_source_v1(input.drawFile,'csv',permission);
        grid=jwpe_b2_source_v1(input.gridFile,'csv',permission);
        require_columns(draws,{'Reactor','ChainID','RowID','kG','tinf','Ai'});
        require_columns(grid,{'Time_d'});times=grid.Time_d(:).';
        assert(height(draws)==500 && isequal(times,0:0.5:94) && ...
            all(string(draws.Reactor)==string(input.reactor)) && ...
            height(unique(draws(:,{'ChainID','RowID'})))==500, ...
            'JWPE:B2:Selection','Use the 500 joint draws and exact accepted 189-time grid.');
        for k=1:4,assert(nnz(draws.ChainID==k)==125,'JWPE:B2:Selection','125 draws/chain required.');end
        values=zeros(500,numel(times));
        for k=1:500
            p=struct('kG',draws.kG(k),'tinf',draws.tinf(k),'Ai',draws.Ai(k));
            assert(all(isfinite([p.kG p.tinf p.Ai])) && p.kG>0 && p.Ai>0 && p.Ai<1, ...
                'JWPE:B2:Activity','Invalid joint capacity parameters.');
            values(k,:)=JWPE_activity_G1(times,p);calls.G1=calls.G1+1;
            assert(all(isfinite(values(k,:))) && all(values(k,:)>0 & values(k,:)<=1) && ...
                all(diff(values(k,:))>=-1e-12) && abs(values(k,1)-p.Ai)<=1e-12);
        end
        q=ppu_math_v1('quantile',values,[0.025 0.5 0.975]);calls.quantile=1;
        records=table(repmat(string(input.reactor),numel(times),1),times(:),q(1,:).',q(2,:).',q(3,:).', ...
            'VariableNames',{'Reactor','Time_d','Q025','Median','Q975'});
        method='NORMALIZED_G1_PAIRED_500_POINTWISE_LINEAR_QUANTILES';
    case "correlations"
        assert(permission.PearsonCallsMax>=5,'JWPE:B2:Quota','Pearson calls not released.');
        chains=jwpe_b2_chains_v1(input,permission);x=vertcat(chains{:});
        pairs=[1 2;2 5;2 4;3 5;6 7];names=string(input.columns(:));
        coefficient=zeros(5,1);
        for k=1:5
            pair=x(:,pairs(k,:));
            assert(all(max(pair,[],1)>min(pair,[],1)), ...
                'JWPE:B2:Degenerate','A constant parameter cannot yield a Pearson coefficient.');
            c=corrcoef(pair);coefficient(k)=c(1,2);calls.Pearson=calls.Pearson+1;
        end
        assert(all(isfinite(coefficient)));
        records=table((1:5).',names(pairs(:,1)),names(pairs(:,2)),coefficient,repmat(size(x,1),5,1), ...
            'VariableNames',{'PairID','ParameterX','ParameterY','Coefficient','SampleCount'});
        method='FIVE_NATIVE_PHYSICAL_PEARSON_PAIRS_ALL_RETAINED_ROWS';
    case "marginals"
        assert(permission.histcountCallsMax>=35,'JWPE:B2:Quota','Marginal calls not released.');
        chains=jwpe_b2_chains_v1(input,permission);x=vertcat(chains{:});
        blocks=cell(7,1);names=string(input.columns(:));
        for p=1:7
            lo=min(x(:,p));hi=max(x(:,p));
            assert(hi>lo,'JWPE:B2:Degenerate','No new-data display fallback for constant parameters.');
            edges=linspace(lo,hi,41);widths=diff(edges);centers=(edges(1:end-1)+edges(2:end))/2;
            combined=histcounts(x(:,p),edges);calls.histcounts=calls.histcounts+1;
            cc=zeros(4,40);cd=zeros(4,40);
            for k=1:4
                cc(k,:)=histcounts(chains{k}(:,p),edges);calls.histcounts=calls.histcounts+1;
                cd(k,:)=cc(k,:)./(size(chains{k},1)*widths);
                assert(sum(cc(k,:))==size(chains{k},1) && abs(sum(cd(k,:).*widths)-1)<=1e-12);
            end
            density=combined./(size(x,1)*widths);
            assert(sum(combined)==size(x,1) && isequal(combined,sum(cc,1)) && ...
                abs(sum(density.*widths)-1)<=1e-12);
            blocks{p}=table(repmat(names(p),40,1),(1:40).',edges(1:end-1).',edges(2:end).',centers.', ...
                combined.',density.',cc(1,:).',cc(2,:).',cc(3,:).',cc(4,:).', ...
                cd(1,:).',cd(2,:).',cd(3,:).',cd(4,:).','VariableNames', ...
                {'Parameter','BinIndex','Left','Right','Center','CombinedCount','CombinedDensity', ...
                'Chain1Count','Chain2Count','Chain3Count','Chain4Count', ...
                'Chain1Density','Chain2Density','Chain3Density','Chain4Density'});
        end
        records=vertcat(blocks{:});method='40_SHARED_MIN_MAX_BINS_COUNTS_OVER_N_WIDTH';
    case "diagnostics"
        if isfield(input,'savedFile') && ~isempty(input.savedFile)
            records=jwpe_b2_source_v1(input.savedFile,'csv',permission);
            require_columns(records,{'Checkpoint','Parameter','Rhat','BulkESS','TailESS'});
            validate_diagnostics(records,input.checkpoints,input.columns);
            method='SAVED_DIAGNOSTIC_HISTORY_UNCHANGED';
        else
            assert(permission.diagnosticCallsMax>=numel(input.checkpoints), ...
                'JWPE:B2:Quota','Retrospective diagnostics have no released calls.');
            chains=jwpe_b2_chains_v1(input,permission);
            assert(numel(unique(input.checkpoints))==numel(input.checkpoints) && ...
                issorted(input.checkpoints) && input.checkpoints(end)==input.rowsPerChain, ...
                'JWPE:B2:Diagnostics','Unique ordered checkpoints must include the final production length.');
            cfg=input.diagnosticConfig;
            assert(isequal(string(cfg.names.physical(:)),string(input.columns(:))));
            blocks=cell(numel(input.checkpoints),1);
            for k=1:numel(input.checkpoints)
                n=input.checkpoints(k);assert(n>=4 && n==floor(n) && n<=input.rowsPerChain);
                prefix=cellfun(@(q)q(1:n,:),chains,'UniformOutput',false);
                d=tb_diag_v1(prefix,cfg,'RETROSPECTIVE_SAVED_CHAIN_PREFIX');calls.diagnostics=calls.diagnostics+1;
                blocks{k}=addvars(d.table,repmat(n,7,1),'Before',1,'NewVariableNames','Checkpoint');
            end
            records=vertcat(blocks{:});validate_diagnostics(records,input.checkpoints,input.columns);
            final=jwpe_b2_source_v1(input.finalDiagnosticsFile,'csv',permission);
            require_columns(final,{'Parameter','Rhat','BulkESS','TailESS'});
            last=records(records.Checkpoint==input.rowsPerChain,:);
            assert(isequal(string(last.Parameter),string(final.Parameter)) && ...
                storage_equal(last{:,{'Rhat','BulkESS','TailESS'}},final{:,{'Rhat','BulkESS','TailESS'}}), ...
                'JWPE:B2:Parity','Final prefix must equal the saved final diagnostic.');
            method='RETROSPECTIVE_PREFIXES_NOT_RUNTIME_HISTORY';
        end
    case "r2_flags"
        records=jwpe_b2_source_v1(input.savedFile,'csv',permission);
        require_columns(records,{'Reactor','R2_rank'});
        records=records(string(records.Reactor)==string(input.reactor),:); % Explicit categorical reactor partition.
        assert(height(records)>0 && ...
            all(isfinite(records.R2_rank)),'JWPE:B2:GSA','Supply explicit reactor-specific saved rows.');
        if ismember('R2_pass',records.Properties.VariableNames)
            method='SAVED_R2_FLAGS_UNCHANGED';
        else
            assert(permission.R2FlagCallsMax>=1 && permission.R2Threshold==0.70 && ...
                strcmp(permission.R2Comparator,'greater_or_equal'),'JWPE:B2:Quota','Unreleased R2 criterion.');
            records.R2_pass=records.R2_rank>=0.70;calls.R2flag=1;
            method='SAVED_R2_GREATER_OR_EQUAL_070_NO_REGRESSION';
        end
    case "external_band"
        if isfield(input,'savedFile') && ~isempty(input.savedFile)
            records=jwpe_b2_source_v1(input.savedFile,'csv',permission);
            require_columns(records,{'Time_d','Q025','Median','Q975'});
            method='SAVED_EXTERNAL_MEAN_BAND_UNCHANGED';
        else
            assert(permission.externalQuantileCallsMax>=1,'JWPE:B2:Quota','External quantiles held.');
            s=jwpe_b2_source_v1(input.predictionFile,'mat',permission);
            assert(isfield(s,'mu') && isfield(s,'times_d') && isreal(s.mu) && ...
                isequal(size(s.mu),[500 numel(s.times_d)]) && all(isfinite(s.mu),'all') && ...
                all(isfinite(s.times_d)) && all(diff(s.times_d)>0), ...
                'JWPE:B2:Shape','Require explicit saved 500-by-time predictions and times.');
            q=ppu_math_v1('quantile',s.mu,[0.025 0.5 0.975]);calls.quantile=1;
            records=table(s.times_d(:),q(1,:).',q(2,:).',q(3,:).', ...
                'VariableNames',{'Time_d','Q025','Median','Q975'});
            method='SAVED_MU_POINTWISE_QUANTILES_NO_INTERPOLATION_OR_NOISE';
        end
    otherwise
        error('JWPE:B2:Product','Unsupported product; no generic scientific entry.');
end

result=struct('classification','B2_STATISTICAL_DERIVATIVE_REVIEW_REQUIRED', ...
    'reactor',input.reactor,'product',char(product),'records',records,'method',method, ...
    'calls',calls,'sourceFiles',permission.inputFiles,'codeFiles',permission.codeFiles, ...
    'mechanisticForwards',0,'optimizerCalls',0,'MCMCTransitions',0, ...
    'observationErrorDraws',0,'posteriorPooling',false,'renderQualified',false);
end

function require_columns(t,names)
assert(istable(t) && all(ismember(names,t.Properties.VariableNames)), ...
    'JWPE:B2:Columns','Saved record schema does not match the explicit producer input.');
end

function pass=storage_equal(binary,textual)
% Same 15-significant-digit CSV comparison as accepted tpost_diag_v1.
pass=isequal(size(binary),size(textual)) && all(isfinite(binary),'all') && ...
    all(isfinite(textual),'all') && ...
    all(strcmp(compose('%.15g',binary),compose('%.15g',textual)),'all');
end

function validate_diagnostics(t,checkpoints,columns)
assert(height(t)==7*numel(checkpoints),'JWPE:B2:Diagnostics','Incomplete diagnostic history.');
for k=1:numel(checkpoints)
    rows=t(t.Checkpoint==checkpoints(k),:);
    assert(height(rows)==7 && isequal(string(rows.Parameter(:)),string(columns(:))) && ...
        all(isfinite(rows{:,{'Rhat','BulkESS','TailESS'}}),'all'), ...
        'JWPE:B2:Diagnostics','Missing/ambiguous checkpoint or parameter rows.');
end
end
