function report=validate_cuves()
% Execute dans MATLAB les essais du VRAI modele, et exporte les traces.
root=fileparts(fileparts(mfilename('fullpath'))); model=build_cuves();
rt=sfroot;
assert(~isempty(rt.find('-isa','Stateflow.Chart','Path',[model '/Sequence'])));
assert(~isempty(rt.find('-isa','Stateflow.Chart','Path',[model '/DP_Control'])));
scenarios={'normal','remote_start','high_B','link_loss','stuck_valve',...
 'link_loss_fill','reset_during_fill'};
report=struct('scenario',{},'passed',{},'message',{});
for n=1:numel(scenarios)
 name=scenarios{n};
 try
  [d,initialB,stopTime]=cuves_scenario(name);
  si=Simulink.SimulationInput(model);
  si=si.setVariable('scenarioData',d,'Workspace',model);
  si=si.setBlockParameter([model '/ManualMode'],'Value','0');
  si=si.setBlockParameter([model '/InitialB'],'Value',num2str(initialB));
  si=si.setModelParameter('StopTime',num2str(stopTime),'EnablePacing','off');
  out=sim(si);
  t=out.cmdLog.time; c=out.cmdLog.signals.values;
  p=out.plantLog.signals.values; b=out.busLog.signals.values;
  ph=out.phaseLog.signals.values;
  assert(all(p(:,1)>=0 & p(:,1)<=100 & p(:,2)>=0 & p(:,2)<=100));
  pump=c(:,4)>.5;
  assert(all(ph(pump)==4 & b(pump,3)>.5 & b(pump,4)<.5 & p(pump,4)<.5 & b(pump,5)>.5));
  assert(all(p(:,7)<1e-9 & p(:,8)<1e-9),'Debordement detecte');
  assert(all(ismember(b(:,10),0:4)),'Etat DP invalide');
  if strcmp(name,'normal')
   assert(all(ismember(0:3,unique(b(:,10)))),'Initialisation Stateflow DP incomplete');
  end
  if ~any(strcmp(name,{'link_loss_fill','reset_during_fill'}))
   for pair=[1 10;2 5;3 15]'
    mask=ph==pair(1); duration=sum(mask)*.01;
    assert(abs(duration-pair(2))<=.03,'Duree de phase incorrecte');
   end
  end
  if any(strcmp(name,{'normal','remote_start','high_B'}))
   assert(any(pump),'La pompe ne demarre pas');
   assert(ph(end)==0 && p(end,1)<=2.05,'Cycle non termine');
  end
  if strcmp(name,'high_B')
   mask=t>36 & t<54; assert(any(ph(mask)==4 & c(mask,4)==0 & b(mask,4)>.5));
   assert(any(t>55 & pump),'Pas de reprise apres vidange de B');
  elseif strcmp(name,'link_loss')
   mask=t>=34.15 & t<39; assert(all(all(c(mask,:)==0)) && all(ph(mask)==9));
   assert(any(b(mask,10)==4),'Le chart DP ne passe pas en defaut');
   assert(ph(end)==0,'Reset du defaut non effectif');
  elseif strcmp(name,'stuck_valve')
   assert(~any(pump) && ph(end)==4,'Pompage avec vanne bloquee');
  elseif strcmp(name,'link_loss_fill')
   mask=t>=5.15 & t<9;
   assert(all(ph(mask)==9) && all(all(c(mask,:)==0)),...
    'Perte du bus pendant le remplissage : repli incorrect');
   assert(ph(end)==0 && b(end,10)==3 && b(end,5)>.5,...
    'Liaison ou acquittement non retabli');
  elseif strcmp(name,'reset_during_fill')
   mask=t>=4.15;
   assert(all(ph(mask)==0) && all(all(c(mask,:)==0)),...
    'Reset pendant le remplissage : commandes non arretees');
   assert(abs(p(end,1))<1e-9 && abs(p(end,2))<1e-9,...
    'Reset du procede incomplet');
  end
  headers={'t','phase','A_L','B_L','positionVA03','NB_A','NH_B','FDCO','spillA','spillB',...
   'VA03_distante','DCY2_recu','FDCO_recu','NH_B_recu','busOK','cycles','age_s','tx0','rx0','etatDP',...
   'VA01','VA02','AGT','PMP01','VA03_demandee'};
  writetable(array2table([t ph p b c],'VariableNames',headers),fullfile(root,'results',[name '.csv']));
  save(fullfile(root,'results',[name '.mat']),'out');
  report(n)=struct('scenario',name,'passed',true,'message','Simulation Simulink et assertions valides');
 catch err
  report(n)=struct('scenario',name,'passed',false,'message',err.message);
 end
end
fid=fopen(fullfile(root,'results','validation_matlab.json'),'w');
if fid<0, error('Cuves:Write','Impossible de sauvegarder le rapport'); end
fprintf(fid,'%s',jsonencode(report)); fclose(fid);
disp(struct2table(report));
assert(all([report.passed]),'Au moins un essai MATLAB a echoue : lire results/validation_matlab.json');
end
