%% Code Information
%************************************************************************
%Stanford GPS

%Function Description: Calculate the average latitude and longitude
%(with error ellips) from the NIC=0 position message reports
%************************************************************************

function [dens]=AvgCent(adsbdata)
    %Filter to only NIC=0 Data
    nic0data=adsbdata;
    %nic0data=adsbdata(adsbdata.nic==0,:);
    x_dot=mean(nic0data.lon);
    y_dot=mean(nic0data.lat);
    cent=[x_dot; y_dot];
    %Calculate Error Ellipse (95 percent confidence interval)
    P=0.95;
    sigma=cov([nic0data.lon,nic0data.lat]);
    [ell_lon,ell_lat,Z]=Err_Ellipse(cent,sigma,P);
    %Plot Centroid Point
    c=geoscatter(cent(2),cent(1),15,"black","filled","diamond");
    %Plot Ellipse
    [cline]=contourc(ell_lon,ell_lat,Z,[1-P 1-P]);
    ell=geoplot(cline(2,2:end),cline(1,2:end),'LineWidth',3);
    dens=[c,ell];
end

%% Other Functions
%Error Ellipse
function [x,y,Z] = Err_Ellipse(cent,sigma,P)
    syms x1 x2
    x=cent(1)-100:.1:cent(1)+100;
    y=cent(2)-100:.1:cent(2)+100;
    [X,Y]=meshgrid(x,y);
    %Full equation of ellipse
    f=([x1 x2]-cent')*inv(sigma)*([x1;x2]-cent)+2*log(1-P);
    zfun=@(x1,x2) eval(vectorize(f));
    Z=zfun(X,Y);
    
end