function [V,F,I_FD] = spatialDecompositionAlpha(X,Y,isIndexed,dx,dy,ext,varargin)
% decomposite the spatial domain into cells D with vertices V,
%
% Input
%  X, Y      - coordinates
%  isIndexed - indexed pixels
%  dx,dy     - spatial resolution
%  ext       - extension
%
% Output
%  V - list of vertices
%  F - list of faces
%  I_FD - incidence matrix between faces to cells
%

% get the alpha parameter
dxy = sqrt(dx * dy);
alpha = dxy * get_option(varargin,'alpha',2.2);

% extend raster by one row / column in all directions
xmin = ext(1); xmax=ext(2); ymin = ext(3); ymax = ext(4);

GridBoundary = [
  repmat(xmin-dx, size(X,1)+2,1), (ymin-dy:dy:ymax+dy).' ; ...
  (xmin:dx:xmax).', repmat(ymin-dy, size(X,2), 1) ; ...
  (xmin:dx:xmax).', repmat(ymax+dy, size(X,2), 1) ; ...
  repmat(xmax+dx, size(X,1)+2,1), (ymin-dy:dy:ymax+dy).'];

% considere only indexed points
x_ = X(isIndexed);
y_ = Y(isIndexed);
lmax = length(x_);

% compute alpha shape
shp = alphaShape(x_,y_,alpha);

% add some grid points that are close to the alpha shape but not inside

% 1. condition: be not inside the alpha shape
toAdd = ~inShape(shp,X,Y);

% 2. condition: dist to alpha shape should be larger dxy
[~,dist] = nearestNeighbor(shp,X,Y);
toAdd  = toAdd & dist > dxy;

% 3. condition: may not be needed 
%toAdd = toAdd & ~inShape(shp,X+(dx/2+eps),Y-(dy/2+eps));
%toAdd = toAdd & ~inShape(shp,X-(dx/2+eps),Y-(dy/2+eps));
%toAdd = toAdd & ~inShape(shp,X+(dx/2+eps),Y+(dy/2+eps));
%toAdd = toAdd & ~inShape(shp,X-(dx/2+eps),Y+(dy/2+eps));

% add points
x_ = [x_; X(toAdd); GridBoundary(:,1)];
y_ = [y_; Y(toAdd); GridBoundary(:,2)];

% final computation of the voronoi decomposition
% V - list of vertices of the Voronoi cells
% D   - cell array of Vornoi cells with centers X_D ordered accordingly
dtri = delaunayTriangulation(x_,y_);
[V,D] = voronoiDiagram(dtri); % this needs the most time

% we are only interested in voronoi cells corresponding to the given
% coordinates - not the dummy coordinates (for the outer boundary)
D= D(1:lmax);

% merge points that coincide
[V,~,ic] = uniquetol(V,1e-5,'ByRows',true,'DataScale',1);
  
% remove duplicated points in D
%D = cellfun(@(x) x(diff([x,x(1)])~=0),D,'UniformOutput',false);
% this is faster then the cellfun approach
for k = 1:length(D)
  x = ic(D{k}).';              % merge points that coincide
  D{k} = x(diff([x,x(1)])~=0); % remove dubplicates in D
end

% now we need some adjacencies and incidences
iv = [D{:}];            % nodes incident to cells D
id = zeros(size(iv));   % number the cells
    
p = [0; cumsum(cellfun('prodofsize',D))];
for k=1:numel(D), id(p(k)+1:p(k+1)) = k; end
    
% next vertex
indx = 2:numel(iv)+1;
indx(p(2:end)) = p(1:end-1)+1;
ivn = iv(indx);

% edges list
F = [iv(:), ivn(:)];

% should be unique (i.e one edge is incident to two cells D)
[F, ~, ie] = unique(sort(F,2),'rows');

% faces incident to cells, F x D
I_FD = sparse(size(F,1),numel(isIndexed));
I_FD(:,isIndexed) = sparse(ie,id,1);
%I_FD = sparse(ie,id,1);

end
