%% Code Information
%*************************************************************************
%Stanford GPS

%Function Description: Provide supplementary functions that filters data,
%plots the cone, and other cone-related functions

%*************************************************************************

classdef Util_Cone
    methods(Static)
        %Convert Cone from ENU to LLA using parameters 
        function [lon_xx,lat_yy,alt_zz]=ConeConvert(filtered_data,origin,A,r)
            %Define Boundaries
            box_x=[min(filtered_data.x),max(filtered_data.x)];
            box_y=[min(filtered_data.y),max(filtered_data.y)];
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
        function Plot_Cone(fig,lat_yy,lon_xx,alt_zz,randomdata)
            ax=get(fig,'CurrentAxes');
            %Setup figure
            hold(ax,"on")
            mesh(ax,lon_xx,lat_yy,alt_zz)
            scatter3(randomdata.lon,randomdata.lat,randomdata.alt,'filled')
            hold(ax,'off')
        end

        %Filter Data (remove data below 100 meters, 
        function [final_data]=Filter_Data(adsbdata)
            %Filter data to 100 feet
            filt_data=adsbdata(adsbdata.z>=100,:);
            %Pick 1000 random samples from data
            final_data=datasample(filt_data,500,1,'Replace',false);
            
        end
    
        %Generate Simulated Data
        function [conedata]=ConeRandData(cent,angle,height)
	        n=100;
	        theta=zeros(n,1);
	        phi=zeros(n,1);
	        z=zeros(n,1);
            mu=[-angle,angle];
            sigma=[5 0;0 5];
            gm=gmdistribution(mu,sigma);
            x=zeros(n,2);
	        for i=1:n
		        theta(i)=randi([0,360],1);
                ind=randi([1, 2],1);
		        dist=random(gm,1);
                phi(i)=dist(ind);
		        z(i)=randi([0,height],1);
		        x(i,1)=z(i)*tand(phi(i))*cosd(theta(i));
		        x(i,2)=z(i)*tand(phi(i))*sind(theta(i));
	        end
	        x_prime=x-cent(1:2);
	        t_prime=z-cent(3);
            conedata=struct('x',x_prime,'t',t_prime);
        end
        
        %plot center of cone on 2d topo map
        function PlotCenter(lat_center,lon_center)
            fig=figure('color','w');
            %plot center
            gx=geoaxes('Basemap','satellite');
            hold(gx,'on')
            geoscatter(lat_center,lon_center,'filled','HandleVisibility','on')
            t=table(lat_center, lon_center,'VariableNames',{'lat','lon'});
            AvgCent(t,fig)
            hold(gx,'off')
        end

        %Locate center of cone
        function [lat_center,lon_center]=LocateCenter(lat_yy,lon_xx,alt_zz)
            [x_ind,y_ind]=find(alt_zz==min(min(alt_zz)));
            lon_center=lon_xx(x_ind,y_ind);
            lat_center=lat_yy(x_ind,y_ind);
        end
    end
end

