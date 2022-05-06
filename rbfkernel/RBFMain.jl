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

#Train Kernel
function TrainKernel(trainingdata)
    k=SqExponentialKernel()∘ ScaleTransform(1.5)
    model = svmtrain(kernelmatrix(k, trainingdata.X), trainingdata.Y; kernel=LIBSVM.Kernel.Precomputed)
    test_range = range(floor(Int, minimum(trainingdata.X)), ceil(Int, maximum(trainingdata.X)); length=100)
    return model, test_range, k
end

#Validate Kernel
function ValidateKernel(test_range,trainingdata,valdata,k)
    x_val = ColVecs(mapreduce(collect, hcat, Iterators.product(test_range, test_range)));
    y_pred, _ = svmpredict(model, kernelmatrix(k, trainingdata.X, valdata.X));
    return x_val, y_pred
end

#Main Script
#Import Data
filename,rawdata=DataProcess.FileUpload()
#Organize and Split into training and validation data, and features/labels
datat,datav=DataProcess.SplitData(rawdata)
#Train Model on Training Data
#model,test_range,k=TrainKernel(datat)
#Validate Model
#x_val,y_pred=ValidateKernel(test_range,datat,datav,k)




#Plot Data
#DataProcess.PlotADSB(datat,datav,model)


