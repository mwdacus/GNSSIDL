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
            lladata=enu2lla([double(x_olv'),double(y_olv'),double(z_olv')-origin(3)],...
                origin,'ellipsoid');
            lat_yy=reshape(lladata(:,1),[n,n]);
            lon_xx=reshape(lladata(:,2),[n,n]);
            alt_zz=reshape(z_olv',[n,n]);
        end

        %Plot cone as a mesh (on top of base layer and 
        function Plot_Cone(lat_yy,lon_xx,alt_zz)
            hold on
            contour3(lon_xx,lat_yy,alt_zz,'ShowText','on')
            hold off
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
        function PlotCenter(lat_center,lon_center,Z,RZ,origin,airport)
            z=geointerp(Z,RZ,lat_center,lon_center,"cubic");
            hold on
            %Add Location of Jammer
            scatter3(lon_center,lat_center,z,30,'red','filled','HandleVisibility','on')
            loclegend=strcat('Jammer Location: ',string(lat_center),', ',...
                string(lon_center),', ',string(z));
            %Add nearest airport
            scatter3(origin(2),origin(1),origin(3),30,"black",'filled',...
                'HandleVisibility','on')
            airportlegend=strcat('Airport Location', airport);
            %Add legend
            qw{1} = plot(nan, 'ro','MarkerFaceColor','r','MarkerSize',10);
            qw{2} = plot(nan, 'ko','MarkerFaceColor','k','MarkerSize',10);
            legend([qw{:}], {loclegend,airportlegend}, 'location', 'best')
            hold off
        end

        %Locate center of cone
        function [lat_center,lon_center]=LocateCenter(lat_yy,lon_xx,alt_zz)
            [x_ind,y_ind]=find(alt_zz==min(min(alt_zz)));
            lon_center=lon_xx(x_ind,y_ind);
            lat_center=lat_yy(x_ind,y_ind);
        end
    end
end

