function value = getOpticalDensity(specs,meta,device,src,LUT,NdCalibrationLabels)
devInfo = meta.Devices(ismember({meta.Devices.Name},device));
ndSplit = strsplit(specs.(src){1},'|');
if any(contains(ndSplit,'path','IgnoreCase',true))
  % Check the meta info for the bound wilter wheel
  devResource = devInfo.Resources(contains({devInfo.Resources.name},'FilterWheel'));
  wheelName = strsplit(devResource.value,'>');
  ndSplit(~contains(ndSplit,wheelName{end},'IgnoreCase',true)) = [];
  ndSplit = regexprep(string(ndSplit),'^W\_','');
  value = LUT.( ...
    NdCalibrationLabels(2) ...
    )( ...
    string(LUT.(NdCalibrationLabels(1))) == ndSplit ...
    );
else
  % expected to be a string label within the nd table and not a property
  value = 0;
  for d = 1:numel(ndSplit)
    nextvalue = LUT.( ...
      NdCalibrationLabels(2) ...
      )( ...
      LUT.(NdCalibrationLabels(1)) == string(ndSplit(d)) ...
      );
    if isempty(nextvalue),nextvalue = 0; end
    value = value + nextvalue;
  end
end
end