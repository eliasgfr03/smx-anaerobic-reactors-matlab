function score = p3d_score_v2(core,holdout,bound,cfg)
%P3D_SCORE_V2 Type-stable Phase-III scoring delta for MATLAB R2022b.

phase3=core.times_d>cfg.prefixEnd_d;
times=core.times_d(phase3); mu=core.mu(:,phase3);
yrep=reshape(core.yrep,cfg.predictiveRows,numel(times));
meanQ=p3v_math_v1('quantile',mu,cfg.quantiles);
predQ=p3v_math_v1('quantile',yrep,cfg.quantiles);
meanNew=local_band(times,meanQ,'NEW_HOLDOUT_MEAN_RESPONSE');
predNew=local_band(times,predQ,'NEW_HOLDOUT_POSTERIOR_PREDICTIVE');
meanOld=bound.meanBand(bound.meanBand.Time_d<=cfg.prefixEnd_d,:);
predOld=bound.predBand(bound.predBand.Time_d<=cfg.prefixEnd_d,:);
meanOld.BandType=repmat("FROZEN_PPU_MEAN_RESPONSE",height(meanOld),1);
predOld.BandType=repmat("FROZEN_PPU_POSTERIOR_PREDICTIVE",height(predOld),1);
fullMean=[meanOld;meanNew]; fullPred=[predOld;predNew];
[found,index]=ismember(holdout.Time_d,times);
assert(all(found) && numel(index)==17,'JWPE:P3D:Score', ...
    'Holdout times are absent from the Phase-III grid.');
n=height(holdout); covered=false(n,1); residual=zeros(n,1);
absoluteResidual=zeros(n,1); squaredResidual=zeros(n,1); crps=zeros(n,1);
meanWidth=zeros(n,1); predWidth=zeros(n,1); pBelow=zeros(n,1);
empiricalBelow=zeros(n,1);
for i=1:n
    observation=holdout.ValidationCout_ug_L(i); column=index(i);
    covered(i)=observation>=predQ(1,column) && observation<=predQ(3,column);
    residual(i)=observation-meanQ(2,column);
    absoluteResidual(i)=abs(residual(i)); squaredResidual(i)=residual(i)^2;
    crps(i)=p3v_math_v1('crps',yrep(:,column),observation);
    meanWidth(i)=meanQ(3,column)-meanQ(1,column);
    predWidth(i)=predQ(3,column)-predQ(1,column);
    pBelow(i)=mean(core.pCens(:,column));
    empiricalBelow(i)=mean(yrep(:,column)<=cfg.lod);
end
point=[holdout table(meanQ(1,index).',meanQ(2,index).',meanQ(3,index).', ...
    predQ(1,index).',predQ(2,index).',predQ(3,index).',covered,meanWidth, ...
    predWidth,residual,absoluteResidual,squaredResidual,crps,pBelow, ...
    empiricalBelow,'VariableNames',{'MeanQ025','MeanMedian','MeanQ975', ...
    'PredictiveQ025','PredictiveMedian','PredictiveQ975','Covered95', ...
    'MeanBandWidth95','PredictiveBandWidth95','Residual','AbsoluteResidual', ...
    'SquaredResidual','CRPS','PosteriorAveragedProbabilityLELOD', ...
    'EmpiricalPredictiveFractionLELOD'})];
summary=table(n,sum(covered),mean(covered),mean(predWidth),median(predWidth), ...
    mean(residual),mean(absoluteResidual),sqrt(mean(squaredResidual)),mean(crps), ...
    'VariableNames',{'N','CoveredCount','DescriptiveCoverageFraction', ...
    'MeanPredictiveBandWidth95','MedianPredictiveBandWidth95','Bias', ...
    'MAE','RMSE','MeanCRPS'});
score=struct('point',point,'summary',summary,'meanPhaseIII',meanNew, ...
    'predictivePhaseIII',predNew,'fullMean',fullMean,'fullPredictive',fullPred);
end

function T=local_band(times,q,type)
T=table(times,repmat(string(type),numel(times),1),q(1,:).',q(2,:).',q(3,:).', ...
    'VariableNames',{'Time_d','BandType','Q025','Median','Q975'});
end

