function conv = g2_conv(history,cfg)
%G2_CONV Apply the approved corrected convergence rule.

assert(~isempty(history),'JWPE:G2:Metric','Checkpoint history is empty.');
conv = repmat(local_empty(),numel(history),1);
streak = 0;
for j=1:numel(history)
    h = history(j);
    c = local_empty();
    c.reactor = h.reactor;
    c.N = h.N;
    c.M_BAL = h.M_BAL;
    c.phaseR2 = h.phaseR2;
    c.timeR2PassCount = h.timeR2PassCount;
    if j<cfg.convergence.historyLength
        c.classI(:) = "INSUFFICIENT_HISTORY";
        c.classII(:) = "INSUFFICIENT_HISTORY";
    else
        MI = vertcat(history(j-2:j).M_I);
        MII = vertcat(history(j-2:j).M_II);
        [c.cvI,c.classI] = local_classify(MI,cfg);
        [c.cvII,c.classII] = local_classify(MII,cfg);
    end
    c.paramGateI = all(endsWith(c.classI,"_PASS"));
    c.paramGateII = all(endsWith(c.classII,"_PASS"));
    c.phaseR2Gate = all(c.phaseR2>=cfg.metric.r2Threshold);
    c.timeR2Gate = c.timeR2PassCount>=cfg.metric.minPassingTimes;
    c.windowPass = c.paramGateI && c.paramGateII && ...
        c.phaseR2Gate && c.timeR2Gate;
    if c.windowPass
        streak = streak+1;
    else
        streak = 0;
    end
    c.consecutivePasses = streak;
    c.globalGate = streak>=cfg.convergence.requiredConsecutiveWindows && ...
        c.N>=cfg.convergence.firstPossibleStopN;
    if c.globalGate
        c.windowState = "SECOND_CONSECUTIVE_WINDOW_PASS";
    elseif c.windowPass && streak==1
        c.windowState = "FIRST_CONSECUTIVE_WINDOW_PASS";
    elseif j<cfg.convergence.historyLength
        c.windowState = "INSUFFICIENT_HISTORY";
    else
        c.windowState = "WINDOW_FAIL";
    end
    maxN = cfg.(h.reactor).budget.mcMax;
    if c.N==maxN && ~c.globalGate
        c.terminalState = "GSA_CONVERGENCE_REVIEW";
    elseif c.globalGate
        c.terminalState = "CONVERGED";
    else
        c.terminalState = "CONTINUE";
    end
    conv(j) = c;
end
end

function [cv,class] = local_classify(M,cfg)
mu = mean(M,1);
amplitude = max(M,[],1)-min(M,[],1);
cv = 100*std(M,0,1)./mu;
class = strings(1,6);
for p=1:6
    if mu(p)<cfg.convergence.lowMeanThreshold
        if amplitude(p)<=cfg.convergence.lowRangeThreshold
            class(p) = "STABLY_LOW_PASS";
        else
            class(p) = "STABLY_LOW_FAIL";
        end
    elseif cv(p)<=cfg.convergence.cvThreshold_pct
        class(p) = "CV_PASS";
    else
        class(p) = "CV_FAIL";
    end
end
end

function c = local_empty()
c = struct('reactor','','N',0,'M_BAL',nan(1,6), ...
    'cvI',nan(1,6),'classI',strings(1,6), ...
    'cvII',nan(1,6),'classII',strings(1,6), ...
    'phaseR2',nan(1,2),'timeR2PassCount',0, ...
    'paramGateI',false,'paramGateII',false,'phaseR2Gate',false, ...
    'timeR2Gate',false,'windowPass',false,'consecutivePasses',0, ...
    'globalGate',false,'windowState',"",'terminalState',"");
end
