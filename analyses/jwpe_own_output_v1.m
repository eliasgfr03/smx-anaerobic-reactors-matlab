function folder=jwpe_own_output_v1(folder)
%JWPE_OWN_OUTPUT_V1 Create an explicit, exclusive result directory.
folder=char(folder);
assert(~isfolder(folder) && ~isfile(folder),'JWPE:Own:Overwrite','Output exists.');
assert(numel(fullfile(folder,'surrogateopt_checkpoint.mat'))<=245, ...
    'JWPE:Own:Path','Output path is too long.');
parent=fileparts(folder);
if ~isfolder(parent)
    [ok,message]=mkdir(parent);assert(ok,'JWPE:Own:Output','%s',message);
end
object=java.io.File(folder);
assert(object.mkdir(),'JWPE:Own:Overwrite','Cannot reserve exclusive output.');
end
