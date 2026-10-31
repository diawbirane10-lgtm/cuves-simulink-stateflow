function fig = cuves_hmi(model)
% IHM MATLAB connectee aux sorties reelles de la simulation Simulink.
if nargin==0, model='Cuves_PROFIBUS_Stateflow'; end
root=fileparts(fileparts(mfilename('fullpath')));
manual=zeros(6,1); releaseAt=[inf inf inf]; history=zeros(0,25); lastTime=-1;
lastPhase=-1; phaseEnteredAt=0;
fig=uifigure('Name','Deux cuves | Supervision Simulink / Stateflow',...
 'Position',[60 35 1500 940],'Color',[0.94 0.96 0.97],'Tag','CuvesHMI');
g=uigridlayout(fig,[4 1]);
g.RowHeight={64,86,'1x',205}; g.RowSpacing=12; g.Padding=[16 14 16 14];
g.BackgroundColor=[0.94 0.96 0.97];
head=uipanel(g,'BackgroundColor',[0.075 0.18 0.26],'BorderType','none');
headGrid=uigridlayout(head,[1 3]); headGrid.ColumnWidth={'1x',170,250};
headGrid.Padding=[18 5 18 5]; headGrid.BackgroundColor=[0.075 0.18 0.26];
uilabel(headGrid,'Text','DEUX CUVES  /  SUPERVISION','FontSize',21,...
 'FontWeight','bold','FontColor',[1 1 1]);
timeLabel=uilabel(headGrid,'Text','t = 0.00 s','FontSize',14,...
 'HorizontalAlignment','center','FontColor',[0.74 0.86 0.91]);
stateLabel=uilabel(headGrid,'Text','Simulation arrêtée','FontSize',14,...
 'FontWeight','bold','HorizontalAlignment','right','FontColor',[0.8 0.9 0.94]);
metrics=uigridlayout(g,[1 4]); metrics.ColumnWidth={'1x','1x','1x','1x'};
metrics.ColumnSpacing=12; metrics.Padding=[0 0 0 0];
metrics.BackgroundColor=g.BackgroundColor;
kpiA=metricCard(metrics,'CUVE A','0.0 L');
kpiB=metricCard(metrics,'CUVE B','0.0 L');
kpiPhase=metricCard(metrics,'ETAPE','ATTENTE');
kpiBus=metricCard(metrics,'BUS DP','INITIALISATION');
body=uigridlayout(g,[1 2]); body.ColumnWidth={'1x',285};
body.ColumnSpacing=12; body.Padding=[0 0 0 0];
body.BackgroundColor=g.BackgroundColor;
tankPanel=uipanel(body,'BackgroundColor',[1 1 1],...
 'BorderType','line','Title','PROCÉDÉ  /  CUVE A → CUVE B',...
 'FontName','Arial','FontSize',12,'FontWeight','bold',...
 'ForegroundColor',[0.13 0.29 0.39]);
tankGrid=uigridlayout(tankPanel,[1 1]); tankGrid.Padding=[8 5 8 5];
ax=uiaxes(tankGrid); ax.XLim=[0 12]; ax.YLim=[0 8]; ax.XTick=[]; ax.YTick=[];
ax.Box='off'; ax.Color=[1 1 1]; hold(ax,'on');
controlPanel=uipanel(body,'BackgroundColor',[1 1 1],...
 'BorderType','line','Title','PILOTAGE',...
 'FontName','Arial','FontSize',12,'FontWeight','bold',...
 'ForegroundColor',[0.13 0.29 0.39]);
controls=uigridlayout(controlPanel,[12 1]);
controls.RowHeight={20,34,34,34,34,34,20,24,24,24,35,34};
controls.RowSpacing=3; controls.Padding=[12 6 12 6];
uilabel(controls,'Text','MODE SIMULATION','FontSize',11,...
 'FontWeight','bold','FontColor',[0.35 0.44 0.5]);
uibutton(controls,'Text','▶  DÉMARRER LA SIMULATION',...
 'BackgroundColor',[0.13 0.43 0.58],'FontColor',[1 1 1],...
 'FontWeight','bold','Tag','StartSimulation','ButtonPushedFcn',@startSim);
uibutton(controls,'Text','■  ARRÊTER',...
 'BackgroundColor',[0.89 0.92 0.94],'FontColor',[0.12 0.25 0.32],...
 'FontWeight','bold','ButtonPushedFcn',@stopSim);
uibutton(controls,'Text','DCY1  ·  Départ local',...
 'BackgroundColor',[0.88 0.94 0.97],'FontColor',[0.1 0.29 0.4],...
 'Tag','DCY1','ButtonPushedFcn',@(~,~)pulse(1));
uibutton(controls,'Text','DCY2  ·  Départ distant',...
 'BackgroundColor',[0.88 0.94 0.97],'FontColor',[0.1 0.29 0.4],...
 'ButtonPushedFcn',@(~,~)pulse(2));
uibutton(controls,'Text','↺  Réinitialiser',...
 'BackgroundColor',[0.95 0.92 0.86],'FontColor',[0.37 0.29 0.18],...
 'ButtonPushedFcn',@(~,~)pulse(3));
uilabel(controls,'Text','DÉFAUTS ET ESSAIS','FontSize',11,...
 'FontWeight','bold','FontColor',[0.35 0.44 0.5]);
uicheckbox(controls,'Text','Couper le bus DP',...
 'Tag','LinkLoss',...
 'ValueChangedFcn',@(s,~)toggle(4,s.Value));
uicheckbox(controls,'Text','Bloquer VA-03 fermée',...
 'Tag','StuckValve',...
 'ValueChangedFcn',@(s,~)toggle(5,s.Value));
uicheckbox(controls,'Text','Vidanger la cuve B',...
 'Tag','DrainB',...
 'ValueChangedFcn',@(s,~)toggle(6,s.Value));
speedRow=uigridlayout(controls,[1 2]); speedRow.ColumnWidth={'1x',82};
speedRow.Padding=[0 0 0 0];
uilabel(speedRow,'Text','Vitesse de simulation','FontSize',11);
speed=uispinner(speedRow,'Limits',[0.2 5],'Value',1,'Step',0.2,...
 'Tag','SimulationSpeed','Tooltip','Vitesse simulation / temps réel');
exports=uigridlayout(controls,[1 3]);
exports.ColumnWidth={'1x','1x','1x'}; exports.Padding=[0 0 0 0];
exports.ColumnSpacing=4;
uibutton(exports,'Text','Stateflow','Tooltip','Ouvrir les deux automates d''etats',...
 'BackgroundColor',[0.9 0.93 0.95],'FontColor',[0.13 0.29 0.39],...
 'Tag','OpenStateflow','ButtonPushedFcn',@openCharts);
uibutton(exports,'Text','Capture','Tooltip','Sauvegarder une image dans results',...
 'BackgroundColor',[0.9 0.93 0.95],'FontColor',[0.13 0.29 0.39],...
 'Tag','CaptureHMI','ButtonPushedFcn',@captureUI);
uibutton(exports,'Text','CSV','Tooltip','Exporter les mesures de la session',...
 'BackgroundColor',[0.9 0.93 0.95],'FontColor',[0.13 0.29 0.39],...
 'Tag','ExportCSV','ButtonPushedFcn',@exportCSV);
% Conduites, cuves et liquide. Le bleu indique une commande/activite.
plot(ax,[1.4 1.4],[7.3 5.7],'Color',[.4 .4 .4],'LineWidth',4);
plot(ax,[3.3 3.3],[7.3 5.7],'Color',[.4 .4 .4],'LineWidth',4);
plot(ax,[3.8 5 7.1 7.1 8.2],[1.8 1.8 1.8 6.2 6.2],'Color',[.4 .4 .4],'LineWidth',5);
fluidA=patch(ax,[1 3.8 3.8 1],[1.3 1.3 1.3 1.3],[.45 .69 .83],'EdgeColor','none');
fluidB=patch(ax,[8.2 11 11 8.2],[1.3 1.3 1.3 1.3],[.45 .69 .83],'EdgeColor','none');
rectangle(ax,'Position',[1 1.3 2.8 4.4],'EdgeColor',[.2 .2 .2],'LineWidth',2);
rectangle(ax,'Position',[8.2 1.3 2.8 4.4],'EdgeColor',[.2 .2 .2],'LineWidth',2);
plot(ax,[2.4 2.4],[6.2 3.5],'Color',[.3 .3 .3],'LineWidth',3);
agit=plot(ax,[1.8 3],[3.5 3.5],'Color',[.4 .4 .4],'LineWidth',5);
val1=valve(1.4,6.5); val2=valve(3.3,6.5); val3=valve(7.1,4.5);
pump=rectangle(ax,'Position',[4.65 1.45 .7 .7],'Curvature',[1 1],...
 'FaceColor',[.85 .85 .85],'LineWidth',2);
text(ax,1.4,7.6,'P1 / VA-01','HorizontalAlignment','center');
text(ax,3.3,7.6,'P2 / VA-02','HorizontalAlignment','center');
text(ax,7.6,4.5,'VA-03'); text(ax,5,1.05,'PMP-01','HorizontalAlignment','center');
text(ax,2.4,.75,'CUVE A - UNITE 1','HorizontalAlignment','center','FontWeight','bold');
text(ax,9.6,.75,'CUVE B - UNITE 2','HorizontalAlignment','center','FontWeight','bold');
levelA=text(ax,2.4,5.25,'0.0 L','HorizontalAlignment','center','FontWeight','bold','FontSize',15);
levelB=text(ax,9.6,5.25,'0.0 L','HorizontalAlignment','center','FontWeight','bold','FontSize',15);
for pct=[0 20 40 60 80 100]
 text(ax,.9,1.3+4.4*pct/100,sprintf('%d',pct),'HorizontalAlignment','right','FontSize',9);
 text(ax,11.1,1.3+4.4*pct/100,sprintf('%d',pct),'FontSize',9);
end
bottom=uigridlayout(g,[1 2]); bottom.ColumnWidth={'2x','1x'};
bottom.ColumnSpacing=12; bottom.Padding=[0 0 0 0];
bottom.BackgroundColor=g.BackgroundColor;
trendPanel=uipanel(bottom,'BackgroundColor',[1 1 1],...
 'BorderType','line','Title','TENDANCES DES VOLUMES',...
 'FontName','Arial','FontSize',12,'FontWeight','bold',...
 'ForegroundColor',[0.13 0.29 0.39]);
trendGrid=uigridlayout(trendPanel,[1 1]); trendGrid.Padding=[8 3 8 3];
trend=uiaxes(trendGrid); hold(trend,'on'); trend.YLim=[0 100];
trend.XLim=[0 65]; grid(trend,'on'); trend.Color=[1 1 1];
xlabel(trend,'Temps de simulation (s)'); ylabel(trend,'Volume (L)');
la=plot(trend,nan,nan,'Color',[.15 .35 .55],'LineWidth',1.5);
lb=plot(trend,nan,nan,'Color',[.55 .35 .15],'LineWidth',1.5);
title(trend,'Cuve A (bleu) | Cuve B (brun)');
diagnosticsPanel=uipanel(bottom,'BackgroundColor',[1 1 1],...
 'BorderType','line','Title','DIAGNOSTIC & BUS DP',...
 'FontName','Arial','FontSize',12,'FontWeight','bold',...
 'ForegroundColor',[0.13 0.29 0.39]);
diagnosticsGrid=uigridlayout(diagnosticsPanel,[1 1]);
diagnosticsGrid.Padding=[8 3 8 3];
status=uitextarea(diagnosticsGrid,'Editable','off','FontName','Consolas','FontSize',11,...
 'Value',{'SIMULATION LOGIQUE PROFIBUS-DP - aucune liaison materielle';...
 'Debits et volumes pedagogiques. DCY2 et VA-03 passent par les octets DP.'});
head.Layout.Row=1; metrics.Layout.Row=2; body.Layout.Row=3; bottom.Layout.Row=4;
tmr=timer('ExecutionMode','fixedSpacing','Period',0.15,'BusyMode','drop','TimerFcn',@tick);
fig.CloseRequestFcn=@closeUI; start(tmr);
 function valueLabel=metricCard(parent,heading,initial)
  card=uipanel(parent,'BackgroundColor',[1 1 1],'BorderType','line');
  cardGrid=uigridlayout(card,[2 1]);
  cardGrid.RowHeight={24,'1x'}; cardGrid.Padding=[14 7 14 7];
  uilabel(cardGrid,'Text',heading,'FontSize',10,'FontWeight','bold',...
   'FontColor',[0.39 0.48 0.54]);
  valueLabel=uilabel(cardGrid,'Text',initial,'FontSize',19,'FontWeight','bold',...
   'FontColor',[0.1 0.3 0.42]);
 end
 function h=valve(x,y)
  h=patch(ax,x+[-.22 .22 .22 -.22],y+[-.22 .22 -.22 .22],...
   [.85 .85 .85],'EdgeColor',[.2 .2 .2],'LineWidth',1.5);
 end
 function startSim(~,~)
  if ~strcmp(get_param(model,'SimulationStatus'),'stopped'), return; end
  history=zeros(0,25); lastTime=-1; lastPhase=-1; phaseEnteredAt=0;
  manual(1:3)=0; releaseAt(:)=inf;
  set_param([model '/ManualMode'],'Value','1'); applyManual();
  set_param(model,'StopTime','inf','EnablePacing','on','PacingRate',num2str(speed.Value));
  set_param(model,'SimulationCommand','start');
 end
 function stopSim(~,~)
  if ~strcmp(get_param(model,'SimulationStatus'),'stopped')
   set_param(model,'SimulationCommand','stop');
  end
 end
 function pulse(i)
  if ~strcmp(get_param(model,'SimulationStatus'),'running')
   uialert(fig,'Demarrer la simulation avant d’appuyer sur ce bouton.','Simulation arretee'); return;
  end
  manual(i)=1; releaseAt(i)=get_param(model,'SimulationTime')+0.30; applyManual();
 end
 function toggle(i,v), manual(i)=double(v); applyManual(); end
 function applyManual(), set_param([model '/ManualInputs'],'Value',mat2str(manual)); end
 function v=readPort(block)
  r=get_param([model '/' block],'RuntimeObject');
  if isempty(r), error('Cuves:IHM','Sortie indisponible : %s',block); end
  v=double(r.OutputPort(1).Data(:));
 end
 function tick(~,~)
  if ~isvalid(fig) || ~bdIsLoaded(model), return; end
  simStatus=get_param(model,'SimulationStatus');
  if ~any(strcmp(simStatus,{'running','paused'})), stateLabel.Text=['Simulation ' simStatus]; return; end
  try
   now=get_param(model,'SimulationTime');
   for i=1:3
    if now>=releaseAt(i), manual(i)=0; releaseAt(i)=inf; applyManual(); end
   end
   p=readPort('PlantState'); b=readPort('BusState'); ph=readPort('PhaseView'); c=readPort('CommandView');
   if now<lastTime, history=zeros(0,25); end
   if now>lastTime, history(end+1,:)=[now p' b' ph(1) c']; lastTime=now; end
   fluidA.YData=[1.3 1.3 1.3+4.4*p(1)/100 1.3+4.4*p(1)/100];
   fluidB.YData=[1.3 1.3 1.3+4.4*p(2)/100 1.3+4.4*p(2)/100];
   levelA.String=sprintf('%.1f L',p(1)); levelB.String=sprintf('%.1f L',p(2));
   kpiA.Text=sprintf('%.1f L',p(1)); kpiB.Text=sprintf('%.1f L',p(2));
   val1.FaceColor=equipmentColor(c(1)); val2.FaceColor=equipmentColor(c(2));
   val3.FaceColor=equipmentColor(b(1)); pump.FaceColor=equipmentColor(c(4)); agit.Color=equipmentColor(c(3));
   names={'ATTENTE','REMPLISSAGE P1','REMPLISSAGE P2','AGITATION','TRANSFERT'};
   if ph(1)==9, stateLabel.Text='DEFAUT BUS - acquitter';
   elseif ph(1)>=0 && ph(1)<=4, stateLabel.Text=names{round(ph(1))+1}; end
   if ph(1)~=lastPhase, lastPhase=ph(1); phaseEnteredAt=now; end
   if ph(1)>=1 && ph(1)<=3
    durations=[10 5 15]; remaining=max(0,durations(round(ph(1)))-(now-phaseEnteredAt));
    kpiPhase.Text=sprintf('%s  |  %.1f s',stateLabel.Text,remaining);
   else
    kpiPhase.Text=stateLabel.Text;
   end
   dpNames={'ATTENTE','PARAMETRAGE','CONFIGURATION','ECHANGE','DEFAUT LIAISON'};
   dpIndex=max(1,min(5,round(b(10))+1)); dpName=dpNames{dpIndex};
   if b(5)>.5
    kpiBus.Text='EN LIGNE'; kpiBus.FontColor=[0.07 0.44 0.33];
   elseif round(b(10))==4
    kpiBus.Text='DEFAUT LIAISON'; kpiBus.FontColor=[0.72 0.22 0.18];
   else
    kpiBus.Text='INITIALISATION'; kpiBus.FontColor=[0.66 0.44 0.10];
   end
   timeLabel.Text=sprintf('t = %.2f s',now);
   la.XData=history(:,1); la.YData=history(:,2); lb.XData=history(:,1); lb.YData=history(:,3);
   alarm='Aucune alarme';
   if round(b(10))==4, alarm='Liaison DP perdue : sorties distantes en repli';
   elseif b(5)<.5, alarm='Initialisation de la liaison DP';
   elseif ph(1)==9, alarm='Bus retabli : appuyer sur Reinitialiser';
   elseif ph(1)==4 && b(4)>.5, alarm='Cuve B au niveau haut : transfert suspendu';
   elseif ph(1)==4 && b(3)<.5, alarm='Attente confirmation ouverture VA-03'; end
   status.Value={sprintf('DP SIMULE | maitre 2 -> esclave 3 | 150 m | 1.5 Mbit/s | cycle choisi 20 ms');...
    sprintf('Stateflow DP : %s | echanges=%.0f | age=%.0f ms | Q4=0x%02X | I4=0x%02X',dpName,b(6),1000*b(7),round(b(8)),round(b(9)));...
    sprintf('NB_A=%d | NH_B=%d | FDCO_VA03=%d',round(p(4)),round(p(5)),round(p(6)));...
    sprintf('VA-03=%.0f %% | PMP-01=%d | AGT=%d',100*p(3),round(c(4)),round(c(3)));...
    ['Diagnostic : ' alarm]};
  catch err
   status.Value={['Lecture IHM : ' err.message];'Les erreurs ne sont pas masquees. Consulter MATLAB et le diagnostic du modele.'};
  end
 end
 function col=equipmentColor(v)
  if v>.5, col=[.15 .45 .65]; else, col=[.72 .74 .76]; end
 end
 function openCharts(~,~)
  open_system([model '/Sequence']);
  open_system([model '/DP_Control']);
 end
 function captureUI(~,~)
  filename=fullfile(root,'results',...
   ['capture_ihm_' datestr(now,'yyyymmdd_HHMMSS') '.png']);
  exportapp(fig,filename);
  uialert(fig,['Capture enregistree : ' filename],'Capture IHM');
 end
 function exportCSV(~,~)
  if isempty(history), uialert(fig,'Aucune mesure enregistree.','Export'); return; end
  [f,d]=uiputfile('*.csv','Exporter les mesures IHM','mesures_ihm.csv');
  if isequal(f,0), return; end
  headers={'t','A_L','B_L','positionVA03','NB_A','NH_B','FDCO','spillA','spillB',...
   'VA03_distante','DCY2_recu','FDCO_recu','NH_B_recu','busOK','cycles','age_s','tx0','rx0','etatDP',...
   'phase','VA01','VA02','AGT','PMP01','VA03_demandee'};
  writetable(array2table(history,'VariableNames',headers),fullfile(d,f));
 end
 function closeUI(~,~)
  stop(tmr); delete(tmr);
  if bdIsLoaded(model), stopSim([],[]); end
  delete(fig);
 end
end
