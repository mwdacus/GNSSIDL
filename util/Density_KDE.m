%% Code Information
%*************************************************************************
%Stanford GPS

%Function Description: Implements a density weighting scheme by using
%kernel density estimation (kde) of adsb data points

%*************************************************************************   

function [f] = Density_KDE(x,y,boxx,boxyy)
    %Calculate bandwidth
    data=[x,y];
    n=size(data,1);
    %kernel density estimation (lat, lon, alt)
    for i=1:size(data,2)
        b(i)=SilvermanBandwidth(data(:,i),n);
    end
    %create meshgrid of weights
    val=50;
    xx=linspace(boxx(1),boxx(2),val);
    yy=linspace(boxyy(1),boxyy(2),val);
%     [xi,yi]=meshgrid(xx,yy);
%     xgrid=reshape(xi,[val^2,1]);
%     ygrid=reshape(yi,[val^2,1]);
    
    w=mvksdensity(data,data,"Kernel","normal",'bandwidth',b);
    %Dense Weight
    alpha=.5;
    ep=0.01;
    %phat=normalize(w,'norm',1);
    f=max(1-alpha*w,ep)/(1/n*sum(max(1-alpha*w,ep)));
%     dens=geodensityplot(ygrid,xgrid,f,'Radius',10000,'FaceColor','interp');
end

%% Local Functions
%Silvermans rule for calculating bandwidth
function [b]=SilvermanBandwidth(data_col,n)
    sigma=std(data_col);
    b=sigma*(4/(5*n))^(1/7);
end

   
