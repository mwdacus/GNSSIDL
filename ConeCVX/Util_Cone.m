%THINGS NEED TO DO
%LLACONEDATA (THE ACTUAL CONE) NEEDS TO BE A SURF PLOT IN 3D,
%PLOT BASE LAYER USING ZIXI
%EXPERIMENT WITH GAMMA TO ADJUST FITTING
%

classdef Util_Cone
    methods(Static)
        %Convert Cone from ENU to LLA using parameters 
        function [lon_xx,lat_yy,alt_zz]=ConeConvert(filtered_data,origin,A,r)
            %Define Boundaries
            box_x=[min(filtered_data(:,1)),max(filtered_data(:,1))];
            box_y=[min(filtered_data(:,2)),max(filtered_data(:,2))];
            n=100;
            x=linspace(box_x(1),box_x(2),100);
            y=linspace(box_y(1),box_y(2),100);
            [xx,yy]=meshgrid(x,y);
            x_olv=reshape(xx,[1,n^2]);
            y_olv=reshape(yy,[1,n^2]);
            fcone=@(x,y) norm(A*[x;y]+r(1:2),2)+r(3);
            for i=1:length(x_olv)
                z_olv(i)=fcone(x_olv(i),y_olv(i));
            end
            lladata=enu2lla([double(x_olv'),double(y_olv'),double(z_olv')],...
                origin,'ellipsoid');
            lat_yy=reshape(lladata(:,1),[n,n]);
            lon_xx=reshape(lladata(:,2),[n,n]);
            alt_zz=reshape(z_olv',[n,n]);
        end

        %Plot cone as a mesh (on top of base layer and 
        function Plot_Cone(fig,lat_yy,lon_xx,alt_zz)
            ax=get(fig,'CurrentAxes');
            %Setup figure
            hold(ax,"on")
            mesh(lon_xx,lat_yy,alt_zz)
            hold(ax,'off')
        end

        %Filter Data (remove data below 100 meters, 
        function [filt_data]=Filter_Data(enudata)
            %Filter data to 100 feet
            filt_data=enudata(enudata(:,3)>=100,:);
            %Pick 1000 random samples from data
            filt_data=datasample(filt_data,1000,1,'Replace',false);
        end
    
        %Generate Simulated Data
        function [conedata]=ConeRandData(cent,angle,height)
	        n=500;
	        theta=zeros(n,1);
	        phi=zeros(n,1);
	        z=zeros(n,1);
            mu=[-angle,angle];
            sigma=[5 0;0 5];
            gm=gmdistribution(mu,sigma);
	        for j=1:(0.5*n)-1
		        theta(j:j+1)=randi([0,360],1,2);
		        phi(j:j+1)=random(gm,1);
		        z(j:j+1)=randi([0,height],1,2);
	        end

	        x=zeros(n,2);
	        for i=1:n
		        x(i,1)=z(i)*tand(phi(i))*cosd(theta(i));
		        x(i,2)=z(i)*tand(phi(i))*sind(theta(i));
	        end
	        x_prime=x-cent(1:2);
	        t_prime=z-cent(3);
            conedata=struct('x',x_prime,'t',t_prime);
        end

    end
end

