function varargout = p3v_cont_v1(action,varargin)
%P3V_CONT_V1 Pure continuation contracts for remap and phase-3 hydraulics.

switch lower(string(action))
    case "remap"
        old=double(varargin{1}(:)); oldN=varargin{2}; newN=varargin{3};
        assert(numel(old)==oldN && oldN==2 && newN==3, ...
            'JWPE:P3V:Remap','Expected the accepted CS 2-to-3 remap.');
        oldEdge=linspace(0,1,oldN+1); newEdge=linspace(0,1,newN+1);
        mapped=zeros(newN,1);
        for j=1:newN
            for k=1:oldN
                overlap=max(0,min(newEdge(j+1),oldEdge(k+1))- ...
                    max(newEdge(j),oldEdge(k)));
                mapped(j)=mapped(j)+overlap*old(k)/(newEdge(j+1)-newEdge(j));
            end
        end
        assert(abs(mean(mapped)-mean(old))<=64*eps(max(1,max(abs(old)))), ...
            'JWPE:P3V:Remap','CS conservative remap failed.');
        varargout{1}=mapped;
    case "phase3"
        reactor=upper(string(varargin{1})); settings=varargin{2};
        if reactor=="CS"
            varargout{1}=struct('phase',3,'N',settings.tanks_in_series(3), ...
                'tm_d',settings.mean_residence_time_h(3)/24,'Dax',NaN,'v',NaN);
        elseif reactor=="PF"
            varargout{1}=struct('phase',3,'N',settings.node_count-2,'tm_d',NaN, ...
                'Dax',settings.axial_dispersion_m2_d(3), ...
                'v',settings.axial_velocity_m_d(3));
        else
            error('JWPE:P3V:Reactor','Invalid reactor.');
        end
    otherwise
        error('JWPE:P3V:Continuation','Unsupported continuation action.');
end
end
