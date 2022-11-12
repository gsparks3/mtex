function SO3F = dot(SO3VF1, SO3VF2, varargin)
% pointwise inner product
%
% Syntax
%   SO3F = dot(SO3VF1, SO3VF2)
%   SO3F = dot(v, SO3VF2)
%   SO3F = dot(SO3VF1, v)
%
% Input
%   SO3VF1, SO3VF2 - @SO3VectorField
%   v - @vector3d
%
% Output
%   SO3F - @SO3Fun
%

if isa(SO3VF2, 'vector3d')
  SO3F = SO3VF1.SO3F;
  SO3F = reshape(sum( SO3F .* reshape(v.xyz.',[3,size(v)]),1),size(v));
  if SO3VF2.antipodal
    SO3F = abs(SO3F);
  end
  return
end

if isa(SO3VF1, 'vector3d')
  SO3F = dot(SO3VF2,SO3VF1);
  return
end

ensureCompatibleSymmetries(SO3VF1,SO3VF2)
f = SO3FunHandle(@(rot) dot(SO3VF1.eval(rot),SO3VF2.eval(rot)));
SO3F = SO3FunHarmonic(f, varargin{:});

end
