function score=jwpe_external_score(core,response)
%JWPE_EXTERNAL_SCORE Mean-response-only diagnostics, not predictive coverage.
q=ppu_math_v1('quantile',core.mu,[.025 .5 .975]);
[found,loc]=ismember(response.Time_d,core.times_d);assert(all(found));
lo=q(1,loc).';med=q(2,loc).';hi=q(3,loc).';y=response.ValidationCout_ug_L;
residual=y-med;contained=y>=lo & y<=hi;
point=[response table(lo,med,hi,residual,contained,'VariableNames', ...
 {'MeanQ025','MeanMedian','MeanQ975','Residual','MeanContained95'})];
labels=[unique(string(response.Phase),'stable');"OVERALL"];n=numel(labels);x=zeros(n,5);
for i=1:n
 if labels(i)=="OVERALL",use=true(height(response),1);else,use=string(response.Phase)==labels(i);end
 e=residual(use);x(i,:)=[nnz(use),mean(e),mean(abs(e)),sqrt(mean(e.^2)),nnz(contained(use))];
end
summary=[table(labels,'VariableNames',{'Phase'}) array2table(x,'VariableNames',{'N','Bias','MAE','RMSE','MeanContainedCount'})];
score=struct('point',point,'summary',summary,'uncertainty','PARAMETRIC_MEAN_RESPONSE_ONLY');
end
