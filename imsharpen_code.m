function B = imsharpen(varargin)

narginchk(1,7);
varargin = matlab.images.internal.stringToChar(varargin);
[A, radius, amount, threshold] = parse_inputs(varargin{:});

if isempty(A)
    B = A;
    return;
end

isRGB = ndims(A) == 3;

if isRGB
    [A, classA] = convertRGB2Lab(A);
    I = A(:,:,1);
else
    I = A;
end

% Gaussian blurring filter
filtRadius = ceil(radius*2); % 2 Standard deviations include >95% of the area. 
filtSize = 2*filtRadius + 1;
gaussFilt = fspecial('gaussian',[filtSize filtSize],radius);

% High-pass filter
sharpFilt = zeros(filtSize,filtSize);
sharpFilt(filtRadius+1,filtRadius+1) = 1;
sharpFilt = sharpFilt - gaussFilt;

if threshold > 0 
    % When threshold > 0, sharpening includes a non-linear (thresholding)
    % step
    
    classI = class(I);
    % Convert image to floating point for computation
    if isinteger(I)
        I = single(I);
    end
    
    % Compute high-pass component
    B = imfilter(I,sharpFilt,'replicate','conv');

    % Threshold the high-pass component
    B = getThresholdedEdgeComponent(B,threshold);

    % Sharpening - add the high-pass component
    B = imlincomb(1,I,amount,B,classI);
else
    % For threshold = 0, sharpening is a linear filtering operation
    
    sharpFilt = amount*sharpFilt;
    % Add 1 to the center element of sharpFilt effectively add a unit
    % impulse kernel to sharpFilt.
    sharpFilt(filtRadius+1,filtRadius+1) = sharpFilt(filtRadius+1,filtRadius+1) + 1;
    B = imfilter(I,sharpFilt,'replicate','conv');
end

if isRGB
    A(:,:,1) = B;        
    B = convertLab2RGB(A, classA);
end

end



function gradientImg = getThresholdedEdgeComponent(gradientImg,threshold)

absGradientImg = abs(gradientImg);
Gmax = max(absGradientImg(:));
t = Gmax * threshold;
gradientImg(absGradientImg < t) = 0;

end



function [I, class_of_I] = convertRGB2Lab(I)

int_type_list = {'int8','int16','uint32','int32'};

class_of_I = class(I);

% Convert I to a double in the range [0 1] if it is of one of the types
% not directly supported by applycform/srgb2lab.

if ismember(class_of_I, int_type_list)
    
    typeMax = double(intmax(class_of_I));
    typeMin = double(intmin(class_of_I));    
    I = (double(I) - typeMin)/(typeMax - typeMin);
    
elseif ismember(class_of_I, 'single')
    
    I = double(I); % If single, keep same range, just cast it as double
    
end    
        
cform = makecform('srgb2lab','AdaptedWhitePoint',whitepoint('d65'));
I = applycform(I, cform);
    
end



function I = convertLab2RGB(I, class_of_I)

cform = makecform('lab2srgb','AdaptedWhitePoint',whitepoint('d65'));
I = applycform(I, cform);

int_type_list = {'int8','int16','uint32','int32'};

% Convert I back to the original input image type if it is of one of the
% types not directly supported by applycform/srgb2lab.

if ismember(class_of_I, int_type_list)
    
    typeMax = double(intmax(class_of_I));
    typeMin = double(intmin(class_of_I));
    I = cast((I*(typeMax - typeMin)) + typeMin, class_of_I);
         
elseif ismember(class_of_I, 'single')
    
    I = single(I); % If single, keep same range, just cast it back to single
    
end    
           
end



function [A, radius, amount, threshold] = parse_inputs(varargin)

A    = varargin{1};
validImageTypes = {'uint8','int8','uint16','int16','uint32','int32', ...
                   'single','double'};
validateattributes(A,validImageTypes,{'nonsparse','real'},mfilename,'A',1);
N = ndims(A);

if (isvector(A) || N > 3)
    error(message('images:imsharpen:invalidInputImage'));
elseif (N == 3)
    if (size(A,3) ~= 3)
        error(message('images:imsharpen:invalidImageFormat'));
    end
end

% Default values for parameters
radius = 1;        
amount = 0.8;      
threshold = 0;     

args_names = {'radius', 'amount','threshold'};

for i = 2:2:nargin
    arg = varargin{i};
    if ischar(arg)        
        idx = find(strncmpi(arg, args_names, numel(arg)));
        if isempty(idx)
            error(message('images:validate:unknownInputString', arg))
        elseif numel(idx) > 1
            error(message('images:validate:ambiguousInputString', arg))
        elseif numel(idx) == 1
            if (i+1 > nargin) 
                error(message('images:validate:missingParameterValue'));             
            end
            if idx == 1
                radius = varargin{i+1};
                validateattributes(radius,{'double'},{'positive','finite', ...
                    'real', 'nonempty','scalar'}, mfilename,'Radius',i);
            elseif idx == 2
                amount = varargin{i+1};
                validateattributes(amount,{'double'},{'nonnegative','finite', ...
                    'real','nonempty','scalar'}, mfilename,'Amount',i);
            elseif idx == 3
                threshold = varargin{i+1};
                validateattributes(threshold,{'double'},{'finite', ...
                    'real','scalar', '>=', 0, '<=', 1}, mfilename, ...
                    'Threshold',i);
            end
        end    
    else
        error(message('images:validate:mustBeString')); 
    end
end

end
