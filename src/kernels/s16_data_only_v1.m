function [value,removed]=s16_data_only_v1(value,location)
%S16_DATA_ONLY_V1 Retain data; replace captured callbacks with inert metadata.
if nargin<2,location="payload";end
removed=cell(0,3);
if isa(value,'function_handle')
    info=functions(value);
    removed={char(location),info.type,info.function};
    value=struct('excludedExecutableMetadata',true,'type',info.type,'functionName',info.function);
elseif isstruct(value)
    names=fieldnames(value);
    for a=1:numel(value)
        for b=1:numel(names)
            [value(a).(names{b}),rows]=s16_data_only_v1(value(a).(names{b}),location+"."+names{b}+"("+a+")");
            removed=[removed;rows]; %#ok<AGROW>
        end
    end
elseif iscell(value)
    for a=1:numel(value)
        [value{a},rows]=s16_data_only_v1(value{a},location+"{"+a+"}");
        removed=[removed;rows]; %#ok<AGROW>
    end
elseif istable(value)
    % Check table values and metadata; never silently sanitize table content.
    [checked,rows]=s16_data_only_v1(table2struct(value,'ToScalar',true),location+".table");
    assert(isempty(rows) && isequaln(checked,table2struct(value,'ToScalar',true)));
    [checked,rows]=s16_data_only_v1(value.Properties.UserData,location+".UserData");
    assert(isempty(rows) && isequaln(checked,value.Properties.UserData));
elseif ~(isnumeric(value) || islogical(value) || ischar(value) || isstring(value))
    error('JWPE:Recovery:UnsupportedType','Unsupported type %s at %s.',class(value),location);
end
end
