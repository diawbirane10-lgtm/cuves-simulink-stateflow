function demarrer_projet()
% Ouvrir ce dossier dans MATLAB, puis saisir : demarrer_projet
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'matlab'));
fprintf('MATLAB %s\n',version); disp(ver('simulink')); disp(ver('stateflow'));
model=build_cuves(); open_system(model); cuves_hmi(model);
end
