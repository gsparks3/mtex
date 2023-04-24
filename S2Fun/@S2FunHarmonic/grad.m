function sVF = grad(sF, varargin)
% calculates the gradient of a spherical harmonic
%
% Syntax
%   sVF = grad(sF) % returns the gradient as a spherical vector field 
%   g = grad(sF, v) % return the gradient in point v as vector3d
%
% Input
%  sF - @S2FunHarmonic
%  v - @vector3d
%
% Output
%  sVF - @sphericalVectorFieldHarmonic
%    g - @vector3d
%

% Use Varshalovich 5.8.3(a) equation (10)&(11):

% fallback to generic method
if check_option(varargin,'check')
  sVF = grad@S2Fun(sF,varargin{:});
  return
end

if nargin>1 && isa(varargin{1},'vector3d') && isempty(varargin{1})
  sVF = vector3d; 
  return
end

% if bandwidth is zero there is nothing to do
if sF.bandwidth == 0 
  if nargin>1
    sVF = vector3d.zeros(size(varargin{1}));
  else
    sVF = S2FunHarmonic(0);
  end
  return; 
end


fhat = zeros((sF.bandwidth+2)^2,3);
for n=0:sF.bandwidth

  FHAT = sF.fhat(n^2+1:(n+1)^2);
  
  % 1st component of gradient
  k = (-n:n)';
  a = n/2*(-1).^(k>=0).*sqrt((n+k+1).*(n+k+2)./((2*n+1)*(2*n+3)));
  ind = (n+1)^2+3:(n+2)^2;
  fhat(ind,1) = fhat(ind,1) + a.*FHAT;
  k = (-n:n-2)';
  b = (n+1)/2*(-1).^(k>=0).*sqrt((n-k-1).*(n-k)./((2*n-1)*(2*n+1)));
  ind = (n-1)^2+1:(n)^2;
  fhat(ind,1) = fhat(ind,1) + b.*FHAT(1:end-2);
  
  % 2nd component of gradient
  k = (-n:n)';
  c = n/2*(-1).^(k<=0).*sqrt((n-k+1).*(n-k+2)./((2*n+1)*(2*n+3)));
  ind = (n+1)^2+1:(n+2)^2-2;
  fhat(ind,2) = fhat(ind,2) + c.*FHAT;
  k = (-n+2:n)';
  d = (n+1)/2*(-1).^(k<=0).*sqrt((n+k-1).*(n+k)./((2*n-1)*(2*n+1)));
  ind = (n-1)^2+1:(n)^2;
  fhat(ind,2) = fhat(ind,2) + d.*FHAT(3:end);
  
  % 3rd component of gradient
  k = (-n:n)';
  e = -n*sqrt(((n+1)^2-k.^2)./((2*n+1)*(2*n+3)));
  ind = (n+1)^2+2:(n+2)^2-1;
  fhat(ind,3) = fhat(ind,3) + e.*FHAT;
  k = (-n+1:n-1)';
  f = (n+1)*sqrt((n^2-k.^2)./((2*n-1)*(2*n+1)));
  ind = (n-1)^2+1:(n)^2;
  fhat(ind,3) = fhat(ind,3) + f.*FHAT(2:end-1);

end

%change basis of the gradient to canonical basis
A = fhat;
fhat(:,1) = A(:,1)+A(:,2);
fhat(:,2) = 1i*(A(:,2)-A(:,1));

sVF = S2VectorFieldHarmonic( S2FunHarmonic(fhat) );

if nargin > 1 && isa(varargin{1},'vector3d')
  v = varargin{1};
  sVF = vector3d(sVF.eval(v));
end

end




% if nargin > 1
%   sF = [sF.drho; sF.dtheta];
%   v = varargin{1};
%   y = eval(sF, v);
%   sVF = ...
%     y(:, 1)./sin(v.theta).^2.*S2VectorField.rho(v)+ ...
%     y(:, 2) .* S2VectorField.theta(v);
% 
%   sVF(isnan(sVF)) = vector3d([0 0 0]);
% 
% else
%   sF = [sF.drho; sF.dtheta];
%   sVF = S2VectorFieldHarmonic(sF);
% end