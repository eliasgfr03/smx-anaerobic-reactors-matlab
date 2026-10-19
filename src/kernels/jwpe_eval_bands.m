function [meanBand,predBand]=jwpe_eval_bands(times,mu,yrep)
%JWPE_EVAL_BANDS Preserve the accepted pointwise median and quantile estimator.
q=ppu_math_v1('quantile',mu,[0.025 .5 .975]);
qp=ppu_math_v1('quantile',reshape(yrep,10000,numel(times)),[0.025 .5 .975]);
meanBand=table(times(:),repmat("MEAN_RESPONSE",numel(times),1),q(1,:).',q(2,:).',q(3,:).', ...
 'VariableNames',{'Time_d','BandType','Q025','Median','Q975'});
predBand=table(times(:),repmat("POSTERIOR_PREDICTIVE",numel(times),1),qp(1,:).',qp(2,:).',qp(3,:).', ...
 'VariableNames',{'Time_d','BandType','Q025','Median','Q975'});
end
