%% Code Information
%*************************************************************************
%Stanford GPS

%Function Description: Implements a density weighting scheme by using
%kernel density estimation (kde) of adsb data points

%*************************************************************************   

function [f] = Density_KDE(x,y,alt)
    %Calculate bandwidth
    data=[x,y,alt];
    n=size(data,1);
    %kernel density estimation (lat, lon, alt)
    for i=1:3
        b(i)=SilvermanBandwidth(data(:,i),n);
    end
    w=mvksdensity(data,data,"bandwidth",b,"Kernel","normal");
    %Dense Weight
    alpha=.8;
    ep=0.1;
    phat=normalize(w,'norm',1);
    f=max(1-alpha*phat,ep)/(1/n*sum(max(1-alpha*phat,ep)));
end

%% Local Functions
%Silvermans rule for calculating bandwidth
function [b]=SilvermanBandwidth(data_col,n)
    sigma=std(data_col);
    b=sigma*(4/(5*n))^(1/7);
end

   
