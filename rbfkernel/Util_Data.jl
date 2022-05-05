#Michael Dacus                                                    Stanford GPS Lab

#Function Description: 
    #Split incoming ADS-B Data into features (x) and labels (y)
    #split data into training and validation data
    #Plot Resulting 2D Topographical map of ADS-B Points along with Classifying Regions
#Input Information: 
    #Raw ADS-B Data (time, position, velocity, aircraft ICAO number and NIC value)
#Output Information: 
    #Data split in between features and labels
#----------------------------------------------------------------------------------
module DataProcess
using CSV
using DataFrames

struct Data
    X::Array{Vector{Float64}}
    Y::Float64
end


#Import Data
function fileupload()
    filename=open_dialog("My Open dialog")
    rawdata=DataFrame(CSV.File(filename))
    return filename,rawdata
end

#Plot Data


end



