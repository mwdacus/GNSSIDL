
using PlotlyJS
using Main.DataProcess
using DataFrames
using Dates

function plotgeo(data)
    plot(data; x=:lat,y=:lon,z=:alt,type="scatter3d",mode="markers",color=:nic)

end
#Import Data
filename,rawdata=DataProcess.FileUpload()
timedata=DataProcess.ReClock(rawdata)
timedata=sort!(timedata)
delta_t=0:5:5
Min=minute.(timedata.mintime)
#Split Data By every 5 minutes, each to be trained on
ind=findall(x->10<x<10+10,Min)
filtereddata=timedata[ind,:]
plotgeo(filtereddata)




