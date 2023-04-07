%% Code Information
%************************************************************************
%Stanford GPS

%Function Description: Run CVX optimzation here

%Input Information: ADS-B data data(x,t), gamma (smoothing parameter

%Output Information: (A: rotation matrix, r: location of center of cone)

%************************************************************************


function [A,r] = ConeCVX(enudata,gamma)
    data=struct('x',enudata(:,1:2),'t',enudata(:,3));
    dim=size(data.x,2);
    n=size(data.x,1);
    cvx_begin
        A=semidefinite(2);
        variable r(3,1);
        variable u(n);
        maximize(log_det(A)-gamma*sum((u-data.t).^2))
        subject to
            for i=1:n
                norm(A*data.x(i,:)'+r(1:2),2)+r(3)-u(i)<=data.t(i);
            end
            u>=0;
            r(3)==min(data.t);
    cvx_end

end

