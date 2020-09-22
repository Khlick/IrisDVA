function session = readIrisData(fileName)
%READIRISDATA Import IrisData Objects to Iris session
%

S = load(fileName,'-mat');
[tf,iData] = utilities.r_isFielda(S,'IrisData');

if ~tf, error('File does not contain an IrisData object.'); end

session = iData.saveAsIrisSession('');

end

