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
    trace=bar(;x=0:length(valdata),y=valdata)
    layout=Layout(;title="Validation Accuracy of ADS-B Data",
        xaxis=attr(title="Validation Subset Number",showgrid=true),
        yaxis=attr(title="Validation Accuracy",showgrid=true),
        font=attr(family="Times New Roman",size=20,color="Black")
        )
    config=PlotConfig(displayModeBar=true,
        toImageButtonOptions=attr(format="png",filename="RBF",height=700,width=1000,scale=1).fields)
    p=plot(trace,layout,config=config)
    display(p)
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
    t1=scatter3d(x=x_kernel[1,:],y=x_kernel[2,:],z=x_kernel[3,:],mode="markers",
        marker=attr(color=y_kernel),
        hovertext=y_kernel,
        opacity=0.2)
    t2=scatter3d(x=x_data[1,:],y=x_data[2,:],z=x_data[3,:],mode="markers",
      marker=attr(color=y_data),
      hovertext=y_data,
      opacity=0.2)
    plot([t1,t2])
end

#Function that uses plots.jl to plot contour
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

#2d geo map
function plotgeo(data,y)
    marker=attr(color=y,
        size=5,
        cmin=0,
        cmax=2,
        colorbar=attr(title="NIC value")
            )
    mapbox=attr(style="open-street-map",
        center=attr(lat=39.861667,lon=-104.6731667),
        zoom=8
        )
    #minor=attr(griddash="dot",nticks=10,showgrid=true,tickmode="auto"))
    data=scattermapbox(lat=data[1,:],lon=data[2,:],
        mode="markers",
        marker=marker,
        text=y)
    layout=Layout(; title="GPS Interference Event, Denver Area, January 2022",
        mapbox=mapbox)
    config=PlotConfig(displayModeBar=true,
        toImageButtonOptions=attr(format="png",filename="RBF",height=1500,width=1500,scale=1).fields)
    p=plot(data,layout,config=config)
    display(p)
end

#Function that plots heatmap of nic values
function PlotMap(x,z)
    mapbox=attr(style="open-street-map",
            center=attr(lat=39.861667,lon=-104.6731667),
            zoom=8)
    data=densitymapbox(; lat=x[1,:],lon=x[2,:],z=z,
            opacity=0.7,
            showscale=true,
            zmin=0,
            zmax=2,
            reversescale=false,
            radius=20,
            title=attr(text="Label Value",font=attr(color="Black",family="Times New Roman",size=20)),
            tickfont=attr(color="Black",family="Times New Roman",size=35)
            )
    layout=Layout(; title="GPS Interference Event, Denver Area, January 2022",
            font=attr(family="Times New Roman",size=24,color="Black"),
            mapbox=mapbox)

    config=PlotConfig(displayModeBar=true,
            toImageButtonOptions=attr(format="png",filename="RBF",height=1500,width=1500,scale=1).fields)
    
    p=plot(data,layout,config=config)
    display(p)

end

end


