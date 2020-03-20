function I = rgb2gray(X)

narginchk(1,1);

isRGB = parse_inputs(X);

if isRGB
    I = images.internal.rgb2graymex(X);
else
    % Color map
    % Calculate transformation matrix
    T    = inv([1.0 0.956 0.621; 1.0 -0.272 -0.647; 1.0 -1.106 1.703]);
    coef = T(1,:);
    I = X * coef';
    I = min(max(I,0),1);
    I = repmat(I, [1 3]);
end


function is3D = parse_inputs(X)

is3D = (ndims(X) == 3);

if is3D
    % RGB
    if (size(X,3) ~= 3)
        error(message('MATLAB:images:rgb2gray:invalidInputSizeRGB'))
    end
    % RGB can be single, double, int8, uint8,
    % int16, uint16, int32, uint32, int64 or uint64
    validateattributes(X, {'numeric'}, {}, mfilename, 'RGB');
    
elseif ismatrix(X)
    % MAP
    if (size(X,2) ~= 3 || size(X,1) < 1)
        error(message('MATLAB:images:rgb2gray:invalidSizeForColormap'))
    end
    % MAP must be double
    if ~isa(X,'double')
        error(message('MATLAB:images:rgb2gray:notAValidColormap'))
    end
    
else
    error(message('MATLAB:images:rgb2gray:invalidInputSize'))
end
