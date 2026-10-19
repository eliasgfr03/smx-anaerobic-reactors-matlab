function varargout=ppu_io_v1(action,varargin)
%PPU_IO_V1 Portable I/O adapter; uses the qualified empty-safe hash.
[varargout{1:nargout}]=jwpe_eval_io(action,varargin{:});
end
