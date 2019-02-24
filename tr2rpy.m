%TR2RPY Convert a homogeneous transform to roll-pitch-yaw angles
%
% RPY = TR2RPY(T, options) are the roll-pitch-yaw angles (1x3)
% corresponding to the rotation part of a homogeneous transform T. The 3
% angles RPY=[R,P,Y] correspond to sequential rotations about the Z, Y and
% X axes respectively. Roll and yaw angles in [-pi,pi) while pitch angle
% in [-pi/2,pi/2).
%
% RPY = TR2RPY(R, options) as above but the input is an orthonormal
% rotation matrix R (3x3).
%
% If R (3x3xK) or T (4x4xK) represent a sequence then each row of RPY
% corresponds to a step of the sequence.
%
% Options::
%  'deg'   Compute angles in degrees (radians default)
%  'xyz'      Return solution for sequential rotations about X, Y, Z axes
%  'zyx'      Return solution for sequential rotations about Z, Y, X axes (default)
%  'yxz'      Return solution for sequential rotations about Y, X, Z axes
%  'arm'      Return solution for sequential rotations about X, Y, Z axes
%  'vehicle'  Return solution for sequential rotations about Z, Y, X axes
%  'camera'   Return solution for sequential rotations about Y, X, Z axes
%
% Notes::
% - There is a singularity for the case where P=pi/2 in which case R is arbitrarily
%   set to zero and Y is the sum (R+Y).
% - Translation component is ignored.
% - Toolbox rel 8-9 has XYZ angle sequence as default.
% - 'arm', 'vehicle', 'camera' are synonyms for 'xyz', 'zyx' and 'yxz'
%   respectively.
% - these solutions are generated by symbolic/rpygen.mlx
%
% See also  rpy2tr, tr2eul.

% Copyright (C) 1993-2019 Peter I. Corke
%
% This file is part of The Spatial Math Toolbox for MATLAB (SMTB).
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
% of the Software, and to permit persons to whom the Software is furnished to do
% so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
% FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
% COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
% IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
% CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%
% https://github.com/petercorke/spatial-math

% TODO singularity for XYZ case,
function [rpy,order] = tr2rpy(R, varargin)
    
    opt.deg = false;
    opt.order = {'zyx', 'xyz', 'arm', 'vehicle', 'yxz', 'camera'};
    opt = tb_optparse(opt, varargin);
    
    s = size(R);
    if length(s) > 2
        rpy = zeros(s(3), 3);
        for i=1:s(3)
            rpy(i,:) = tr2rpy(R(:,:,i), varargin{:});
        end
        return
    end
    rpy = zeros(1,3);   
    
    
    assert(isrot(R) || ishomog(R), 'SMTB:tr2rpy:badarg', 'argument must be a 3x3 or 4x4 matrix');
    switch opt.order
        case {'xyz', 'arm'}
            opt.order = 'xyz';
            % XYZ order
            if abs(abs(R(1,3)) - 1) < eps  % when |R13| == 1
                % singularity
                rpy(1) = 0;  % roll is zero
                if R(1,3) > 0
                rpy(3) = atan2( R(3,2), R(2,2));   % R+Y
                else
                     rpy(3) = -atan2( R(2,1), R(3,1));   % R-Y
                end
                rpy(2) = asin(R(1,3));
            else
                rpy(1) = -atan2(R(1,2), R(1,1));
                rpy(3) = -atan2(R(2,3), R(3,3));
                
                [~,k] = max(abs( [R(1,1) R(1,2) R(2,3) R(3,3)] ));
                switch k
                    case 1
                        rpy(2) =  atan(R(1,3)*cos(rpy(1))/R(1,1));
                    case 2
                        rpy(2) = -atan(R(1,3)*sin(rpy(1))/R(1,2));
                    case 3
                        rpy(2) = -atan(R(1,3)*sin(rpy(3))/R(2,3));
                    case 4
                        rpy(2) =  atan(R(1,3)*cos(rpy(3))/R(3,3));
                end
            end
            
        case {'zyx', 'vehicle'}
            opt.order = 'zyx';
            % old ZYX order (as per Paul book)
            if abs(abs(R(3,1)) - 1) < eps  % when |R31| == 1
                % singularity

                rpy(1) = 0;     % roll is zero
                if R(3,1) < 0
                    rpy(3) = -atan2(R(1,2), R(1,3));  % R-Y
                else
                    rpy(3) = atan2(-R(1,2), -R(1,3));  % R+Y
                end
                rpy(2) = -asin(R(3,1));
            else
                rpy(1) = atan2(R(3,2), R(3,3));  % R
                rpy(3) = atan2(R(2,1), R(1,1));  % Y
                     
                [~,k] = max(abs( [R(1,1) R(2,1) R(3,2) R(3,3)] ));
                switch k
                    case 1
                        rpy(2) = -atan(R(3,1)*cos(rpy(3))/R(1,1));
                    case 2
                        rpy(2) = -atan(R(3,1)*sin(rpy(3))/R(2,1));
                    case 3
                        rpy(2) = -atan(R(3,1)*sin(rpy(1))/R(3,2));
                    case 4
                        rpy(2) = -atan(R(3,1)*cos(rpy(1))/R(3,3));
                end
            end
            
        case {'yxz', 'camera'}
            opt.order = 'yxz';
            if abs(abs(R(2,3)) - 1) < eps  % when |R23| == 1
                % singularity
                
                rpy(1) = 0;
                if R(2,3) < 0
                    rpy(3) = -atan2(R(3,1), R(1,1));   % R-Y
                else
                    rpy(3) = atan2(-R(3,1), -R(3,2));   % R+Y
                end
                
                rpy(2) = -asin(R(2,3));    % P
            else
                rpy(1) = atan2(R(2,1), R(2,2));
                rpy(3) = atan2(R(1,3), R(3,3));
                
                [~,k] = max(abs( [R(2,1) R(2,2) R(1,3) R(3,3)] ));
                switch k
                    case 1
                        rpy(2) = -atan(R(2,3)*sin(rpy(1))/R(2,1));
                    case 2
                        rpy(2) = -atan(R(2,3)*cos(rpy(1))/R(2,2));
                    case 3
                        rpy(2) = -atan(R(2,3)*sin(rpy(3))/R(1,3));
                    case 4
                        rpy(2) = -atan(R(2,3)*cos(rpy(3))/R(3,3));
                end
            end
            
    end
    if opt.deg
        rpy = rpy * 180/pi;
    end
    if nargout > 1
        order = opt.order;
    end
end
