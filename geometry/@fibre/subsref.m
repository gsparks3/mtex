function varargout = subsref(f,s)
%overloads subsref

switch s(1).type
  case '()'
    
    f.h = subsref(f.h,s(1));
    f.r = subsref(f.r,s(1));
          
    if numel(s)>1
      [varargout{1:nargout}] = builtin('subsref',f,s(2:end));
    else
      varargout{1} = f;
    end  
  otherwise
    
    [varargout{1:nargout}] = builtin('subsref',f,s);
      
end
end
