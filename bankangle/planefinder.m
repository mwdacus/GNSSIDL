%% Code Information
%*************************************************************************
%Problem Statement: Find the plane where the squared-sum of the distances
%from all points is minimized (use Gradient Descent)
%Also find the circle that fits the data in the 2D plane

%Imported Data:
%Turning Information (x,y,z)
%*************************************************************************


function [phi,n,omega] = planefinder(turningdata)
    
    m=length(turningdata);
    k=1:m;
    theta=[2;3];
    a=0.2;
    iters=50;
    p=[turningdata.x(k);turningdata.y(k);turningdata(k)];
    
    %find best plane among turning data
    [n,p_0]=GradDescent(p,theta,a,iters);
    %project 3D points in plane to curve
    [x,y]=transform(n,p_0);
    turnradius()
    theta_conv=GradDescent(p,theta,a,iters);
   

    

end

function [planedata]=transform(n,p_0)

end

function [x0,y0,R_t]=turnradius(planedata)

end

%Create a separate Function for gradient descent 
function [n,p_0]=GradDescent(p,theta,a,iters)
    for i=1:iters
        theta=theta-a*[sum(p-theta(2));-sum(theta(1))];
    end
    n=theta_conv(1);
    p_0=theta_conv(2);
end




    
