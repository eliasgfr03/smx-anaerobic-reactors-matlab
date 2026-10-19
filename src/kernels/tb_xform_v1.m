function [out,detail] = tb_xform_v1(action,value,cfg)
%TB_XFORM_V1 Exact Stage-1 sampled/physical/legacy transformations.

if nargin<3, cfg = tb_cfg_v1(); end
action = lower(string(action)); value = double(value);
assert(size(value,2)==7 && all(isfinite(value),'all'), ...
    'JWPE:TB:Transform','Expected a finite N-by-7 matrix.');
switch action
    case "to_physical"
        g = local_logistic(value(:,3)); a = local_logistic(value(:,5));
        sref = exp(value(:,6)); rho = local_logistic(value(:,7));
        sigmaA = sref.*sqrt(1-rho);
        sigmaP = sref.*sqrt(rho)./cfg.transform.Cref;
        out = [value(:,1:2),0.03+1.97*g,value(:,4),a,sigmaA,sigmaP];
        logJ = log(1.97)-local_softplus(-value(:,3))- ...
            local_softplus(value(:,3))-local_softplus(-value(:,5))- ...
            local_softplus(value(:,5))+log(sigmaA)+log(sigmaP)-log(2);
        detail = struct('g',g,'Ai',a,'sref',sref,'rho',rho,'logJ',logJ);
    case "from_physical"
        local_interior(value,cfg);
        sigmaA = value(:,6); sigmaP = value(:,7);
        uG = log((value(:,3)-0.03)./(2-value(:,3)));
        uA = log(value(:,5)./(1-value(:,5)));
        sref = sqrt(sigmaA.^2+(cfg.transform.Cref*sigmaP).^2);
        rho = (cfg.transform.Cref*sigmaP).^2./sref.^2;
        out = [value(:,1:2),uG,value(:,4),uA,log(sref), ...
            log(rho./(1-rho))];
        [~,detail] = tb_xform_v1('to_physical',out,cfg);
    case "legacy_to_z"
        physical = [value(:,1:5),exp(value(:,6:7))];
        [out,detail] = tb_xform_v1('from_physical',physical,cfg);
        detail.physical = physical;
    case "physical_to_legacy"
        local_interior(value,cfg);
        out = [value(:,1:5),log(value(:,6:7))];
        detail = struct('columnContract', ...
            '[Kd,kb,kG,tinf,Ai,log(sigmaA),log(sigmaP)]');
    otherwise
        error('JWPE:TB:Transform','Unsupported transform action: %s.',action);
end
if action~="to_physical"
    assert(all(isfinite(out),'all'),'JWPE:TB:Transform', ...
        'Transformation returned a nonfinite coordinate.');
end
end

function y = local_logistic(x)
y = zeros(size(x)); positive = x>=0;
y(positive) = 1./(1+exp(-x(positive)));
e = exp(x(~positive)); y(~positive) = e./(1+e);
end

function y = local_softplus(x)
y = max(x,0)+log1p(exp(-abs(x)));
end

function local_interior(x,cfg)
assert(all(arrayfun(@(i)tb_support_v1(x(i,:),cfg),1:size(x,1))) && ...
    all(x(:,6:7)>0,'all'), ...
    'JWPE:TB:Transform','Physical state is not in the open transform interior.');
end
