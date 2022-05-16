#Michael Dacus                                                    Stanford GPS Lab

#Function Description: 
    #Implment an RBF Kernel Function on ADS-B Data to Determine and localize GNSS Interference Source
#Input Information: 
    #Raw ADS-B Data (time, position, velocity, aircraft ICAO number and NIC value)
#Output Information: 
    #Resulting Plot of Interference Region based on Kernel Function
#----------------------------------------------------------------------------------

#CURRENT ISSUE: NEED TO RUN DATA ON GPU (PARALLEL COMPUTING)

using CSV
using DataFrames
using LinearAlgebra
using KernelFunctions
using LIBSVM
using Main.DataProcess
using Dates



#Train Kernel
function TrainKernel(trainingdata,box)

    k=SqExponentialKernel()∘ ScaleTransform(1.5)
    model = svmtrain(kernelmatrix(k, trainingdata.X), trainingdata.Y; kernel=LIBSVM.Kernel.Precomputed)
	test_range_lat=range(box[3], box[4]; length=100)
	test_range_lon=range(box[1], box[2]; length=100)
    x_val = ColVecs(mapreduce(collect, hcat, Iterators.product(test_range_lat, test_range_lon)));
    y_pred, _ = svmpredict(model, kernelmatrix(k, trainingdata.X, x_val));
    return test_range_lat, test_range_lon, y_pred
end

#Main Function
function main()
    #Import Data
    filename,rawdata=DataProcess.FileUpload()
    #Reprocess time to datetime
    timedata=DataProcess.ReClock(rawdata)
    timedata=sort!(timedata)
    delta_t=0:5:1
    Min=minute.(timedata.mintime)
    #Split Data By every 5 minutes, each to be trained on
    # for t=delta_t
    #     #DataProcess.PlotADSB(test_range_lat,test_range_lon,y_pred,filtereddata)
    # end


    ind=findall(x->0<x<5,Min)
    filtereddata=timedata[ind,:]
    datat,datav,box=DataProcess.SplitData(filtereddata)
    (test_range_lat, test_range_lon, y_pred)=TrainKernel(datat,box)
    DataProcess.PlotADSB(test_range_lat,test_range_lon,y_pred,datat)
end



#Main Script
main()

