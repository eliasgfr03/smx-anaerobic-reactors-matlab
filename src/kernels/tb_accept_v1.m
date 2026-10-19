function [accepted,uniformDraw] = tb_accept_v1(alpha)
%TB_ACCEPT_V1 Pinned acceptance-uniform consumption rule.

assert(isscalar(alpha) && isfinite(alpha) && alpha>=0 && alpha<=1, ...
    'JWPE:TB:Sampler','Invalid Metropolis alpha.');
uniformDraw = NaN;
if alpha==1
    accepted = true;
elseif alpha==0
    accepted = false;
else
    uniformDraw = rand();
    accepted = uniformDraw<alpha;
end
end
