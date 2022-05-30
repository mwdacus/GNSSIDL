
using PlotlyJS
using Main.DataProcess
using DataFrames
using Dates

#3d data
function plot3d(data)

    plot(data; x=:lat,y=:lon,z=:alt,type="scatter3d",mode="markers",color=:nic)
    
end

#2d geo map
function plotgeo(data,box)
    marker=attr(color=data.nic,
        size=5,
        cmin=0,
        cmax=7,
        colorbar=attr(title="NIC value"),

            
            
            )
    mapbox=attr(style="open-street-map",
        center=attr(lat=(box[1]+box[2])/2,lon=(box[3]+box[4])/2),   
        zoom=6    
        )
    data=scattermapbox(data; lat=:lat,lon=:lon,
        mode="markers",
        marker=marker,
        text=:nic)
    layout=Layout(; title="GPS Interference Event, Denver Area, January 2022",
        mapbox=mapbox)

    plot(data,layout)
end

function plotmain()
    #Import Data
    filename,rawdata=DataProcess.FileUpload()
    timedata=DataProcess.ReClock(rawdata)
    timedata=sort!(timedata)
    Min=minute.(timedata.mintime)
    #Split Data By every 5 minutes, each to be trained on
    ind=findall(x->0<x<15,Min)
    filtereddata=timedata[ind,:]
    indalt=findall(x->x<5000,filtereddata.alt)
    filtereddata=filtereddata[indalt,:]
    indnic=findall(x->x<=6,filtereddata.nic)
    filtereddata=filtereddata[indnic,:]
    box=[maximum(filtereddata.lat), minimum(filtereddata.lat),maximum(filtereddata.lon),minimum(filtereddata.lon)]
    plotgeo(filtereddata,box)
end

function mapboxtest()
    plot(contour(x=[-105.5,-105, -104.5, -104,-103.5],
    y=[38,38.5,39,39.5,40,40.5],
        z=[
            0      0      1       1     1
            0    1       2      2      1
            1      1      2         1      1
            1    2       1     1       0
            0        0      0        0      0
        ]',
        colorscale="Hot",
        contours_start=0,
        contours_end=2,
        contours_size=1
    ))
    return x,y,z
end

plotmain()

