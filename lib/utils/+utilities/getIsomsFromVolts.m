function isoms = getIsomsFromVolts( ...
  v, ...
  stimulusDuration, ...
  stimulusWavelength, ...
  specs, meta, device, ...
  predictionPadding, ...
  collectingArea, ...
  spectralTemplateLambda, ...
  LedCalibrationFile, ...
  LedCalibrationLabels, ...
  NdCalibrationFile, ...
  NdCalibrationLabels, ...
  NdSources, ...
  ExtraStimNd, ...
  ExtraBgNd ...
  )

%% Validate

arguments
  v (1,:) double
  stimulusDuration (1,:) double {isSameLength(v,stimulusDuration)}
  stimulusWavelength (1,:) double {isSameLength(v,stimulusWavelength)}
  specs
  meta
  device
  predictionPadding (1,1) double {mustBeInRange(predictionPadding,0,999,"exclude-lower")} =2
  collectingArea (1,1) double =0.26
  spectralTemplateLambda (1,1) double =498
  LedCalibrationFile (1,1) string ="X:\My Drive\Sampath\_data\_Calibrations\current\2020-Aug-01_LedCalibration.mat"
  LedCalibrationLabels (1,:) string =["StimVoltage","PhotonDensity"]
  NdCalibrationFile (1,1) string ="X:\My Drive\Sampath\_data\_Calibrations\nd\NDCAL_20200801.mat"
  NdCalibrationLabels (1,:) string =["Id","Measured"]
  NdSources (1,:) string =["device_LEDNDFilterWheels_Current","device_FN_PTFilterWheel_Current"]
  ExtraStimNd (1,1) double =0
  ExtraBgNd (1,1) double =0
end

%% Compute

import utilities.predictLocalLinear
import utilities.getOpticalDensity
import utilities.A2PigmentTemplateFactory


% parse
% load the calibration table
if isempty(LedCalibrationFile) || strcmpi(LedCalibrationFile,'select')
  [b,a] = uigetfile({'*.mat','Calibration Table'}, 'Select Calibration Table');
  if ~b(1), error('Calibration table is required.'); end
  LedCalibrationFile = fullfile(a,b);
end
LedCalibration = importdata(LedCalibrationFile);

if strcmpi(NdCalibrationFile,'select')
  [b,a] = uigetfile({'*.mat','Calibration Table'}, 'Select Calibration Table');
  if ~b(1), error('Nd table is required.'); end
  NdCalibrationFile = fullfile(a,b);
end
NdCalibration = importdata(NdCalibrationFile);

pigmentTemplate = A2PigmentTemplateFactory(spectralTemplateLambda,1);

isoms = v;

for i = 1:numel(v)
  stimTable = LedCalibration( ...
    LedCalibration.Wavelength == stimulusWavelength(i), ...
    LedCalibrationLabels ...
    );
  
  ndTable = NdCalibration( ...
    NdCalibration.Wavelength == stimulusWavelength(i), ...
    NdCalibrationLabels ...
    );
  
  absorptionFactor = pigmentTemplate(stimulusWavelength(i));
  
  intens = predictLocalLinear( ...
    v(i), ...
    stimTable.(LedCalibrationLabels(1)), ...
    stimTable.(LedCalibrationLabels(2)), ...
    predictionPadding ...
    );
  intens = intens * stimulusDuration(i);
  
  stimNd = 0;
  for n = 1:numel(NdSources)
    src = NdSources(n);
    value = getOpticalDensity(specs,meta,device,src,ndTable,NdCalibrationLabels);
    if isempty(value),value = 0; end
    stimNd = stimNd + value;
  end
  
  intens = intens *  10^(-(stimNd+ExtraStimNd));
  isoms(i) = round(intens * collectingArea * absorptionFactor,4,'significant');
end

end


function isSameLength(a,b)
if numel(a) ~= numel(b)
  error("Duration and Volts not the same number of elements."); 
end
end
