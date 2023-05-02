%% Code Information
%*************************************************************************
%Stanford GPS

%Function Description: Implements a density weighting scheme by assigning a
%lower weight to positioning messages near the airport (or are on
%arrival/departure procedures)

%*************************************************************************    

function [w_norm]=Density_Weight(enudata)
    r=100;
    n=size(enudata,1);
    dist=zeros(n,1);w=zeros(n,1);
    for i=1:n
        for j=1:n
            if i==j
                continue
            else
                pointi=[enudata.x(i) enudata.y(i) enudata.z(i)];
                pointj=[enudata.x(j) enudata.y(j) enudata.z(j)];
                dist(j)=norm(pointi-pointj,2);
            end
        end
        %Calculate weight at point i
        inside_rad=sum(dist>=r);
        w(i)=inside_rad/n;
    end
    %normalize weights
    w_norm=normalize(w,'norm',1);    
end