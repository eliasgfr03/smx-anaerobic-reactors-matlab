function varargout = pf_dax_guard_v1(action,varargin)
%PF_DAX_GUARD_V1 Pure STOP guards shared by QA and the manual controller.

switch lower(string(action))
    case "nonbaseline"
        f = varargin{1}; baseline = varargin{2};
        assert(f~=baseline,'JWPE:PFDAX:BaselineForward', ...
            'A mechanistic forward at f=1 is prohibited.');
    case "freshroot"
        assert(~isfolder(varargin{1}),'JWPE:PFDAX:Overwrite', ...
            'The scientific output root already exists.');
    case "storage"
        bytes = varargin{1}; maximum = varargin{2};
        assert(bytes<=maximum,'JWPE:PFDAX:Storage', ...
            'The compact package exceeds the 25 MiB hard maximum.');
    case "failure"
        error('JWPE:PFDAX:ForwardFailure','Synthetic or scientific forward failure STOP.');
    case "next"
        completed = logical(varargin{1}(:));
        index = find(~completed,1,'first');
        if isempty(index), index = numel(completed)+1; end
        varargout{1} = index;
    otherwise
        error('JWPE:PFDAX:Guard','Unsupported PF DAX guard action.');
end
end
