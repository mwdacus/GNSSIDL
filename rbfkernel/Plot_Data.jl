#Michael Dacus                                                    Stanford GPS Lab

#Function Description: 
    #Plot Data for various metrics, including validation accuracy, average lat/lon Algorithm
    #and contour plot
#Input Information: 
    #Accuracy, and Average Lat/Lon Points
#Output Information: 
    #Plots
#----------------------------------------------------------------------------------

module PlotData

using PlotlyJS
using Statistics

#Plot Accuracy
function PlotValAccuracy(accdata)
    valdata=reduce(vcat,accdata)
    trace=scatter(;x=0:length(valdata),y=valdata,mode="markers")
    layout=Layout(;title="Validation Accuracy of ADS-B Data",
        xaxis=attr(title="Time Step Interval",showgrid=true),
        yaxis=attr(title="Validation Accuracy",showgrid=true)
        )
    plot(trace,layout)
end

#Plot Average NIC 0 Distance Algorithm
function PlotAverage(avgdata)
    centerdata=reduce(vcat,avgdata)
    mapbox=attr(style="open-street-map",
        center=attr(lat=mean(centerdata[:,1]),lon=mean(centerdata[:,2]),zoom=6)
        )
    c=scattermapbox(;lat=centerdata[:,1],lon=centerdata[:,2])
    shape=Vector(undef,size(centerdata,1))
    for i=1:size(centerdata,1)
        shape[i]=circle(xref="x",yref="y",
            lat=centerdata[i,2]-centerdata[i,4],lon=centerdata[i,1]-centerdata[i,3],
            lat1=centerdata[i,2]+centerdata[i,4],lon1=centerdata[i,1]+centerdata[i,3],
            opacity=0.2         
            )
    end
    layout=Layout(; title="GPS Interference Event, Denver Area, January 2022",
        mapbox=mapbox,shapes=shape)

        plot(c,layout)

end

#Plot Contour Plots
function PlotContour(x_kernel,y_kernel,x_data,y_data)
    t1=scatter3d(x=x_kernel[:,2],y=x_kernel[:,1],z=x_kernel[:,3],mode="markers",
        marker=attr(color=y_kernel),
        hovertext=y_kernel,
        opacity=0.2)
    t2=scatter3d(;x=x_data[:,2],y=x_data[:,1],z=x_data[:,3],mode="markers",
        marker=attr(color=y_data),
        hovertext=y_data)

    plot([t1, t2])



end

function oldcontour(x,y,y_pred)
    test_range_lon=unique(y)
    test_range_lat=unique(x)
    contourf(
	    test_range_lon,
	    test_range_lat,
	    y_pred;
	    levels=3,
	    color=cgrad([:blue,:red,:green]),
	    alpha=0.8,
	    colorbar_title="prediction",
	)

end

function PlotMap(x,z,box)
    mapbox=attr(style="open-street-map",
    center=attr(lat=(box.NE[2]+box.SE[2])/2,lon=(box.NE[1]+box.NW[1])/2),   
        zoom=7    
        )
    data=densitymapbox(; lat=x[:,2],lon=x[:,1],z=z,
        opacity=0.7,
        showscale=true,
        zmin=0,
        zmax=2,
        radius=50)
    layout=Layout(; title="GPS Interference Event, Denver Area, January 2022",
    mapbox=mapbox)
    plot(data,layout)



end

end
