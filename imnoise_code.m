function b = imnoise(varargin)

  
args = matlab.images.internal.stringToChar(varargin);
[a, code, classIn, classChanged, p3, p4] = ParseInputs(args{:});

b = images.internal.algimnoise(a, code, classIn, classChanged, p3, p4);

% ParseInputs

function [a, code, classIn, classChanged, p3, p4, msg] = ParseInputs(varargin)

% Initialization
p3           = [];
p4           = [];
msg = '';

% Check the number of input arguments.

narginchk(1,4);

% Check the input-array type.
a = varargin{1};
validateattributes(a, {'uint8','uint16','double','int16','single'}, {}, mfilename, ...
              'I', 1);

% Change class to double
classIn = class(a);
classChanged = 0;

if ~isa(a, 'double')
  a = im2double(a);
  classChanged = 1;
else
  % Clip so a is between 0 and 1.
  a = max(min(a,1),0);
end

% Check the noise type.
if nargin > 1
  if ~ischar(varargin{2})
    error(message('images:imnoise:invalidNoiseType'))
  end
  
  % Preprocess noise type string to detect abbreviations.
  allStrings = {'gaussian', 'salt & pepper', 'speckle',...
                'poisson','localvar'};
  idx = find(strncmpi(varargin{2}, allStrings, numel(varargin{2})));
  switch length(idx)
   case 0
    error(message('images:imnoise:unknownNoiseType', varargin{ 2 }))
   case 1
    code = allStrings{idx};
   otherwise
    error(message('images:imnoise:ambiguousNoiseType', varargin{ 2 }))
  end
else
  code = 'gaussian';  % default noise type
end 

switch code
 case 'poisson'
  if nargin > 2
    error(message('images:imnoise:tooManyPoissonInputs'))
  end
  
  if isa(a, 'int16')
    error(message('images:imnoise:badClassForPoisson'));
  end
  
 case 'gaussian'
  p3 = 0;     % default mean
  p4 = 0.01;  % default variance
  
  if nargin > 2
    p3 = varargin{3};
    if ~isRealScalar(p3)
      error(message('images:imnoise:invalidMean'))
    end
  end
  
  if nargin > 3
    p4 = varargin{4};
    if ~isNonnegativeRealScalar(p4)
      error(message('images:imnoise:invalidVariance', 'gaussian'))
    end
  end
  
 case 'salt & pepper'
  p3 = 0.05;   % default density
  
  if nargin > 2
    p3 = varargin{3};
    if ~isNonnegativeRealScalar(p3) || (p3 > 1)
      error(message('images:imnoise:invalidNoiseDensity'))
    end
    
    if nargin > 3
      error(message('images:imnoise:tooManySaltAndPepperInputs'))
    end
  end
  
 case 'speckle'
  p3 = 0.05;    % default variance
  
  if nargin > 2
    p3 = varargin{3};
    if ~isNonnegativeRealScalar(p3)
      error(message('images:imnoise:invalidVariance', 'speckle'))
    end
  end
  
  if nargin > 3
    error(message('images:imnoise:tooManySpeckleInputs'))
  end
  
 case 'localvar'
  if nargin < 3
    error(message('images:imnoise:toofewLocalVarInputs'))
    
  elseif nargin == 3
    % IMNOISE(a,'localvar',v)
    code = 'localvar_1';
    p3 = varargin{3};
    if ~isNonnegativeReal(p3) || ~isequal(size(p3),size(a))
      error(message('images:imnoise:invalidLocalVarianceValueAndSize'))
    end
    
  elseif nargin == 4
    % IMNOISE(a,'localvar',IMAGE_INTENSITY,NOISE_VARIANCE)
    code = 'localvar_2';
    p3 = varargin{3};
    p4 = varargin{4};
    
    if ~isNonnegativeRealVector(p3) || (any(p3) > 1)
      error(message('images:imnoise:invalidImageIntensity'))
    end
    
    if ~isNonnegativeRealVector(p4)
      error(message('images:imnoise:invalidLocalVariance'))
    end
    
    if ~isequal(size(p3),size(p4))
      error(message('images:imnoise:invalidSize'))
    end
    
  else
    error(message('images:imnoise:tooManyLocalVarInputs'))
  end
  
end

% isReal

function t = isReal(P)
%   isReal(P) returns 1 if P contains only real  
%   numbers and returns 0 otherwise.
  isFinite  = all(isfinite(P(:)));
  t = isreal(P) && isFinite && ~isempty(P);



% isNonnegativeReal

function t = isNonnegativeReal(P)
%   isNonnegativeReal(P) returns 1 if P contains only real  
%   numbers greater than or equal to 0 and returns 0 otherwise.

  t = isReal(P) && all(P(:)>=0);



% isRealScalar

function t = isRealScalar(P)
%   isRealScalar(P) returns 1 if P is a real, 
%   scalar number and returns 0 otherwise.

  t = isReal(P) && (numel(P)==1);



% isNonnegativeRealScalar

function t = isNonnegativeRealScalar(P)
%   isNonnegativeRealScalar(P) returns 1 if P is a real, 
%   scalar number greater than 0 and returns 0 otherwise.

  t = isReal(P) && all(P(:)>=0) && (numel(P)==1);



% isVector

function t = isVector(P)
%   isVector(P) returns 1 if P is a vector and returns 0 otherwise.

  t = ((numel(P) >= 2) && ((size(P,1) == 1) || (size(P,2) == 1)));



% isNonnegativeRealVector

function t = isNonnegativeRealVector(P)
%   isNonnegativeRealVector(P) returns 1 if P is a real, 
%   vector greater than 0 and returns 0 otherwise.

  t = isReal(P) && all(P(:)>=0) && isVector(P);
