%% Code Information
%*************************************************************************
%Stanford GPS

%Function Description: Implements a density weighting scheme by assigning a
%lower weight to positioning messages near the airport (or are on
%arrival/departure procedures)

%*************************************************************************    

function [w_norm]=Density_Euclid(x,y,alt)
    data=[x,y,alt];
    r=10000;
    n=size(data,1);
    dist=zeros(n,1);w=zeros(n,1);
    for i=1:n
        pointi=[data(i,1) data(i,2) data(i,3)];
        dist=sum((pointi.*ones(n,3)-data).^2,2).^(.5);
        %Calculate weight at point i
        inside_rad=sum(dist<=r);
        w(i)=inside_rad/n;
    end
    %normalize weights
    w_norm=normalize(w,'norm',1);    
end