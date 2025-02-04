function varargout = fibonacciS2Grid_find(fibgrid, v)
% return index of the grid point closest to v
%
% Input
%   fibgrid     - @fibobacciS2Grid
%   v           - @vector3d
%
% Output:
%   ind         - int32
%   dist        - double

% get parameters of v
n = (numel(fibgrid.x) - 1) / 2;
s = size(v, 1);
theta = v.theta;
rho = mod(v.rho, 2*pi);

% initialize the returning values of the function
ind = zeros(s, 1);
dist = zeros(s, 1);

% we need this to avoid massive overhead when calling v(k) for all k
fibgrid_xyz = fibgrid.xyz;
v_xyz = v.xyz;

% the resolution is slightly bigger than the max separation between 2 nodes
epsilon = fibgrid.resolution;

% sort rho  and get the corresponding index vectors
% if the grid is large it may be useful to save the precise rho values
% during construction in the options and retrieve them here 
try 
  rhoGrid = fibgrid.opt.rho;
catch 
  rhoGrid = mod(fibgrid.rho, 2*pi);
end
[rhoGrid_sorted,sort_id,rank_id] = unique(rhoGrid);

% the rho values are not uniformly distributed on [0,2*pi] which is why we
% have to assume that the rho difference between consecutive rho values
% (sorted by rho) is bigger than the expected value which is 2*pi / (2*n+1)
rhodiff = diff(rhoGrid_sorted);
rhodiff_max = max(rhodiff);
rhoscale = rhodiff_max * (2*n+1)/(2*pi);

% if theta_big is true the index set I gets too large and it is faster to
% first compute the index range with respect to theta and cut out all
% indice where theta is out of bounds afterwards
% this is the exact same approach as here, but in different order with
% respect to rho and theta
% it should be faster due to the reduced average size of the relevant
% indice that remains after the first step
% TODO: this should also be dependent on epsilon
theta_crit = asin(0.825);
theta_big = abs(pi/2 - theta) > theta_crit;

% compute the index range for theta
thetamin = max(theta-epsilon, 0);
thetamax = min(theta+epsilon, pi);
thetamin_id = max(floor(-(2*n+1)/2 * cos(thetamin)) + n+1, 1);
thetamax_id = min( ceil(-(2*n+1)/2 * cos(thetamax)) + n+1, 2*n+1);

% compute the maximal allowed rho derivtion
% rho is not uniformly distributed on [0,2*pi] thus we have to scale the
% region w.r.t. rho by the ratio of the largest and the expected difference
% between consecutive rho angles
epsilon_rho = rhoscale * ...
  min(acos((max(cos(epsilon)-v.z.^2, 0)) ./ (1-v.z.^2)), pi);
rhomin = mod(rho - epsilon_rho, 2*pi);
rhomax = mod(rho + epsilon_rho, 2*pi);
rhomin_id = max(floor(rhomin * (2*n+1)/(2*pi)), 1);
rhomax_id = min( ceil(rhomax * (2*n+1)/(2*pi)), 2*n+1);
swap = rhomin > rhomax;

% mark rows where the center is so close to the pole that we use all points
% close enough to the pole as potential neighbors
homerun = (epsilon_rho > pi-rhodiff_max) | (abs(pi/2-theta) > pi/2-1.2*epsilon);

for k = 1:s
  % if rho region is very big use all points with suitable theta angle
  if homerun(k)
    best_id = (thetamin_id(k) : thetamax_id(k))';

    % if theta is big enough the region with respect to theta is smaller
    % than with respect to rho
    % thus compute all grid points that are suitable w.r.t. theta and
    % then filter out the ones where rho is out of bounds
  elseif theta_big(k)
    % grid indice suitable w.r.t. theta
    I = (thetamin_id(k) : thetamax_id(k))';
    % get the rho indice if sorted by rho
    rank_rho = rank_id(I);
    % filter out by index (faster than by value)
    rho_good = (rank_rho >= rhomin_id(k)) & (rank_rho <= rhomax_id(k));
    % swap upper and lower bounds if the rho interval contains 0 = 2*pi
    if swap(k)
      rho_good = ~rho_good;
    end
    % use the indice where also rho fits
    best_id = I(rho_good);

    % same as above but vice versa
  else
    % make the index vectors with respect to rho_sorted
    if swap(k)
      I = [1 : rhomax_id(k) rhomin_id(k) : 2*n+1]';
    else
      I = (rhomin_id(k) : rhomax_id(k))';
    end
    % get the grid indice if sorted by theta (as in construction)
    rank_theta = sort_id(I);
    % mark the ones where theta is in the suitable range
    theta_good = (rank_theta >= thetamin_id(k)) & ...
      (rank_theta <= thetamax_id(k));
    % only choose those as potential neighbors
    best_id = rank_theta(theta_good);
  end

  % compute the distances
  dist_temp = acos(sum(fibgrid_xyz(best_id,:) .* v_xyz(k,:), 2));
  [d, id] = min(dist_temp);
  dist(k) = d;
  ind(k) = best_id(id);
end

varargout{1} = ind;
varargout{2} = dist;

end