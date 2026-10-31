function files=capturer_demo_ihm()
% Verifie l'IHM en direct et capture le transfert puis le defaut bus.
root=fileparts(fileparts(mfilename('fullpath')));
model=build_cuves();
fig=cuves_hmi(model);
files=struct('transfert',fullfile(root,'results','ihm_transfert.png'),...
 'defaut',fullfile(root,'results','ihm_defaut_bus.png'));
try
 speed=findall(fig,'Tag','SimulationSpeed'); speed.Value=5;
 startButton=findall(fig,'Tag','StartSimulation');
 dcy1=findall(fig,'Tag','DCY1');
 linkLoss=findall(fig,'Tag','LinkLoss');
 assert(~isempty(startButton) && ~isempty(dcy1) && ~isempty(linkLoss));
 feval(startButton.ButtonPushedFcn,startButton,[]);
 waitUntil(0.3,20);
 feval(dcy1.ButtonPushedFcn,dcy1,[]);
 waitUntil(33,45);
 assert(phaseValue()==4,'La simulation n''est pas en transfert');
 pause(0.4); exportapp(fig,files.transfert);
 linkLoss.Value=true;
 feval(linkLoss.ValueChangedFcn,linkLoss,[]);
 t0=tic;
 while phaseValue()~=9
  assert(toc(t0)<10,'Le defaut bus n''a pas ete detecte');
  pause(0.1);
 end
 pause(0.4); exportapp(fig,files.defaut);
 fprintf('Captures IHM : %s et %s\n',files.transfert,files.defaut);
catch err
 if isvalid(fig), close(fig); end
 rethrow(err);
end
if isvalid(fig), close(fig); end

 function waitUntil(target,timeout)
  t0=tic;
  while get_param(model,'SimulationTime')<target
   assert(toc(t0)<timeout,'Temps d''attente de la simulation depasse');
   pause(0.1);
  end
 end
 function value=phaseValue()
  r=get_param([model '/PhaseView'],'RuntimeObject');
  value=double(r.OutputPort(1).Data);
 end
end
