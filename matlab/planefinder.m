%% Code Information
%*************************************************************************
%Problem Statement: Find the plane where the squared-sum of the distances
%from all points is minimized (use Gradient Descent)

%Imported Data:
%Turning Information (x,y,z)
%*************************************************************************


function [n,p_0] = planefinder(turningdata)
    a=0.2;
    iters=50;
    m=length(turningdata);
    k=1:m;
    theta=[2;3];
    p=[turningdata.x(k);turningdata.y(k);turningdata(k)];
    for i=1:iters
        theta=theta-a*[sum(p-theta(2));-sum(theta(1))];
    end
    
    n=theta(1);
    p_0=theta(2);
end
