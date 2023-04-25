# GNSS IDL (Interference, Detection, Localization Repository)
## Overview: Operation and Package Dependencies
This repository contains the various developed algorithms for detecting and locating terrestrial GNSS/RFI Interference sources using ADS-B (Automatic Dependent Surveillance-Broadcast) Data. This repository is called by using `MAIN_EventUpload.mlapp` within [ADSBPlot](https://github.com/mwdacus/ADSBPlot), an interactive interface that allows user to select the appropriate IDL algorithm. If `ADSBPlot` is not available, users can simply call the appropriate function. Additionally, if user plans to used run the Cone Fitting Problem (ConeCVX), they must first install CVX, which is discussed further below.

In order to operate any of the algorithms, a dataset containing ADS-B positions is needed (`adsbdata`). This table should at least include {icao24,nic,lat,lon,alt,mintime}, but can include additional information as well. 

In addition, in order to be able to filter the data accordingly (see "Filtering Schemes" below), the user should also provide elevation data `Z` and georeference data `RZ` generate from the `readgeoraster()` command from a tiff file. In order to generate the elevation data for a given ADS-B dataset, visit [ADSBPlot](https://github.com/mwdacus/ADSBPlot) to generate a mat file that includes this information.

## IDL Algorithms
As it will be mentioned further, all of the ADS-B IDL algorithms are filtered and weighted using the designated Filtering scheme (by aircraft, and density).

### AvgCent
`AvgCent` simply calculates the mean centroid (latitude, longitude) and a 95 percent confidence ellipse from ADS-B positions indicating a NIC value of 0 ("aircraft potentially impacted by interference"). The ellipse/centroid location are then plotted on the same 2D topographic plot.

### Cone Fitting Problem 
#### Convex Formulation (ConeCVX)
This algorithm formulates the area of interface as a conic hull problem, and uses CVX (can be downloaded/installed [here](http://cvxr.com/cvx/)) to solve the optimization problem. This problem is convex, and should be solvable in finite time. The goal is to find the optimal fitting cone from aircraft potentially affected by interference. The main optimization variables are the Cone Design Matrix $A$ and the center of the cone $r$. The formulation also applies a slack variable $u_{i}$ to each of the reported ADS-B positions to avoid overfitting. A weighting parameter $w_{i}$ is introduced, which is based on data density (see "Weighting" Section). After transforming the data to Euclidean Space (ENU), the convex problem is solved. With $A$ and $r$ determined, it can be used to reconvert the data back LLA (Latitude-Longitude-Altitude) Coordinates for further data viewing.
%INCLUDE PICTURE HERE OF CONE 

To see a simulated example of the convex formulation, run `SimulateCone.m`.
#### NonConvex Formulation (ConeNonCVX)
%(Determine Formulation)

### Support Vector Machine (SVM)
%(Determine Formulation)
%(INCLUDE PICTURE OF DECISION BOUNDARIES OVER ADS-B DATA)


## Filtering Scheme
### Aircraft Filtering
To filter the ADS-B data down to managable storage size (and computational time to solve problem), Part-121 aircraft (Commercial and Regional Air Traffic, not Private) are only used. In addition, aircraft reporting above 500' AGL (using `geointerp` function, along with provided elevation data) will also be removed in order to provide a cleaner localization solution. Finally - for certain localization algorithms - data is further reduced to aircraft impacted by some form of interference (i.e. NIC=0 in ADS-B message).

### Weighting
For this problem, the weighting calculation for each for ADS-B position is based on density scheme, where points that are closer to others are assigned a lower weight than ADS-B positions farther away from each other. This weighting scheme prevents the algorithm from overfitting on data more concentrated near dense arrival/departure procedures, and airports.

Several Weighting schemes were implemented, more specifically `DenseWeight`, which uses Kernel Density estimator (KDE) estimator as the primary means for creating the weights (cite paper). In addition, a Euclidean Weighting scheme was also implemented (`Euclid_Weight`), where a radius of 100m around each aircraft's position is used as a boundary to determine how many other ADS-B positions existed within that boundary. By determining the fraction of ADS-B points that lie within the boundary (with respect to all ADS-B points), this will serve as the appropriate density weight for that point.

## References:
For further details on either the SVM or Convex Formulations, please read the ION GNSS+ paper found in on the [Stanford GPS] (http://web.stanford.edu/group/scpnt/gpslab/pubs/papers/Dacus_ION_GNSS_2022_RFI_position_estimation.pdf) Lab's website.

%(Add Density Weighting Scheme Reference (DenseWeight))
