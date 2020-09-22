function [output1,output2] = analysisTemplate(Data,input1,input2)
%% ANALYSISTEMPLATE
% ENTER ANALYSIS DESCRIPTIONS HERE
%
% ----------------------------------------------------------------------- %
% README!!!
% ---------- %
% This template has a special syntax for Iris.
%
% It is always best to put some sort of description in the header of
% the analysis function so that you, and/or others, can understand the
% purpose of the function as well as all the arguments (input and output).
% It is also very good practice to keep a log of changes and notes related
% to the function's purpose up here.
%
% First, we must have Data as the first argument to the function. This
% argument will be of class irisData, the file should be on your MATLAB
% path so you can use it without running Iris in a later MATLAB session.
% This object has a few convenience methods builtin that help you perform
% common tasks such as averaging groups of Datums. For a detailed
% description of the included mehtods, see doc('Iris').
%
% Next, any input can have, but doesn't require, default values which
% we can set in a special syntax, shown below. Briefly, using the block
% comment tags %{...%}, and the definition sign, a colon followed by an
% equals sign, we can set default values. 
%
% It is important that 1) argument default names are case-sensitive and
% MUST match the argument name in the function definition line and 2) must
% be valid MATLAB expressions, that is, if you need it to be a char vector,
% then you must wrap the text in single quotes. Note that spaces are
% ignored but each definition MUST ONLY BE ONE LINE. The parser will ignore
% any line breaks and using the MATLAB newline syntax, ..., will break the
% parser.
%
% --- SET YOUR DEFAULTS BELOW --- %
%{
DEFAULTS
input1:=(1:10)
input2:={'a','cell','of','strings'}
%}

%% Begin Analysis
output1 = cumsum(input1);
output2 = strjoin(input2, ' ');

fprintf( ...
  'Analysis completed on files: %s.\n', ...
  strjoin(Data.meta.fileList, ', ') ...
  );
% end of analysis
end