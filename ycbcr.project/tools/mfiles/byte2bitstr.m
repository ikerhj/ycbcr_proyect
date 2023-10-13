function bitstr = byte2bitstr(byte,length)

if nargin < 1
  error('Need to have the input argument');
end

if ~isscalar(byte)
  warning('Input argument is not a scalar. I cast it simply to a scalar (if possible)');
  byte = byte(1);
end

if byte > 255 || byte < 0
  error('Input is not a byte')
end

bitstr = [int2str(bitget(uint8(byte),8)) ...
          int2str(bitget(uint8(byte),7)) ...
          int2str(bitget(uint8(byte),6)) ...
          int2str(bitget(uint8(byte),5)) ...
          int2str(bitget(uint8(byte),4)) ...
          int2str(bitget(uint8(byte),3)) ...
          int2str(bitget(uint8(byte),2)) ...
          int2str(bitget(uint8(byte),1))];

if exist("length","var")
  if isscalar(length)
    length = abs(round(length));
    if length > 0 && length < 8
      bitstr = bitstr(9-length : end);
    end
  end
end

end
