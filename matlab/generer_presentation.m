function files=generer_presentation()
% Exporte des supports de soutenance depuis le modele et les traces MATLAB.
root=fileparts(fileparts(mfilename('fullpath')));
outdir=fullfile(root,'results');
model='Cuves_PROFIBUS_Stateflow';
load_system(fullfile(root,'generated',[model '.slx']));
files=struct();
files.model=fullfile(outdir,'schema_simulink.png');
files.sequence=fullfile(outdir,'chart_sequence.png');
files.dp=fullfile(outdir,'chart_dp_control.png');
files.traces=fullfile(outdir,'traces_soutenance.png');
files.video=fullfile(outdir,'rejeu_perte_liaison.mp4');
print(['-s' model],'-dpng',files.model);
sfprint([model '/Sequence'],'png',files.sequence);
sfprint([model '/DP_Control'],'png',files.dp);

normal=readtable(fullfile(outdir,'normal.csv'));
fault=readtable(fullfile(outdir,'link_loss.csv'));
fig=figure('Visible','off','Color','w','Position',[100 100 1400 850]);
tiledlayout(fig,2,2,'Padding','compact','TileSpacing','compact');
ax=nexttile; plot(ax,normal.t,normal.A_L,'LineWidth',2,'Color',[.12 .40 .64]); hold(ax,'on');
plot(ax,normal.t,normal.B_L,'LineWidth',2,'Color',[.69 .40 .16]);
title(ax,'Cycle normal · niveaux'); ylabel(ax,'Volume (L)'); grid(ax,'on');
legend(ax,{'Cuve A','Cuve B'},'Location','best');
ax=nexttile; stairs(ax,normal.t,normal.phase,'LineWidth',1.8,'Color',[.13 .40 .60]);
hold(ax,'on'); stairs(ax,normal.t,normal.etatDP,'LineWidth',1.3,'Color',[.50 .32 .60]);
title(ax,'Cycle normal · deux charts Stateflow');
ylabel(ax,'Code etat'); ylim(ax,[-.3 5]); grid(ax,'on');
legend(ax,{'CPU · Sequence','Liaison · DP Control'},'Location','best');
ax=nexttile; plot(ax,fault.t,fault.A_L,'LineWidth',2,'Color',[.12 .40 .64]); hold(ax,'on');
plot(ax,fault.t,fault.B_L,'LineWidth',2,'Color',[.69 .40 .16]);
xline(ax,34,'--','Coupure DP','Color',[.75 .18 .16]);
xline(ax,39,'--','Retour DP','Color',[.12 .50 .31]);
title(ax,'Perte de liaison · niveaux'); xlabel(ax,'Temps simule (s)');
ylabel(ax,'Volume (L)'); grid(ax,'on');
legend(ax,{'Cuve A','Cuve B'},'Location','best');
ax=nexttile; stairs(ax,fault.t,fault.phase,'LineWidth',1.8,'Color',[.13 .40 .60]);
hold(ax,'on'); stairs(ax,fault.t,fault.etatDP,'LineWidth',1.3,'Color',[.50 .32 .60]);
xline(ax,34,'--','Coupure DP','Color',[.75 .18 .16]);
xline(ax,39,'--','Retour DP','Color',[.12 .50 .31]);
title(ax,'Perte de liaison · defaut memorise CPU');
xlabel(ax,'Temps simule (s)'); ylabel(ax,'Code etat'); ylim(ax,[-.3 10]); grid(ax,'on');
legend(ax,{'CPU · Sequence','Liaison · DP Control'},'Location','best');
sgtitle(fig,'DEUX CUVES  /  VALIDATION STATEFLOW','FontSize',17,'FontWeight','bold');
exportgraphics(fig,files.traces,'Resolution',170);
close(fig);

% Rejeu accelere de la simulation link_loss, distinct d'une capture ecran.
fig=figure('Color',[.96 .98 .99],'Position',[100 100 1200 680],...
 'MenuBar','none','ToolBar','none','NumberTitle','off','Name','Rejeu deux cuves');
ax=axes(fig,'Position',[.04 .08 .92 .81]); hold(ax,'on');
axis(ax,[0 12 0 8]); axis(ax,'off');
plot(ax,[3.3 5.7 7.8],[1.2 1.2 1.2],'-','Color',[.30 .36 .40],'LineWidth',7);
plot(ax,[2.1 2.1],[7 5.8],'-','Color',[.30 .36 .40],'LineWidth',5);
plot(ax,[8.9 8.9],[7 5.8],'-','Color',[.30 .36 .40],'LineWidth',5);
fluidA=patch(ax,[.8 3.3 3.3 .8],[1.2 1.2 1.2 1.2],[.26 .60 .82],'EdgeColor','none');
fluidB=patch(ax,[7.8 10.3 10.3 7.8],[1.2 1.2 1.2 1.2],[.26 .60 .82],'EdgeColor','none');
rectangle(ax,'Position',[.8 1.2 2.5 4.6],'EdgeColor',[.13 .25 .32],'LineWidth',3);
rectangle(ax,'Position',[7.8 1.2 2.5 4.6],'EdgeColor',[.13 .25 .32],'LineWidth',3);
text(ax,2.05,.65,'CUVE A','HorizontalAlignment','center','FontSize',16,'FontWeight','bold');
text(ax,9.05,.65,'CUVE B','HorizontalAlignment','center','FontSize',16,'FontWeight','bold');
aText=text(ax,2.05,6.2,'0 L','HorizontalAlignment','center','FontSize',18,'FontWeight','bold');
bText=text(ax,9.05,6.2,'0 L','HorizontalAlignment','center','FontSize',18,'FontWeight','bold');
timeText=text(ax,6,7.4,'','HorizontalAlignment','center','FontSize',19,'FontWeight','bold');
phaseText=text(ax,6,5.9,'','HorizontalAlignment','center','FontSize',14);
dpText=text(ax,6,5.3,'','HorizontalAlignment','center','FontSize',14);
alarmText=text(ax,6,4.6,'','HorizontalAlignment','center','FontSize',14,'FontWeight','bold');
pumpText=text(ax,6,2.2,'','HorizontalAlignment','center','FontSize',14);
phaseNames={'ATTENTE','REMPLISSAGE P1','REMPLISSAGE P2','AGITATION','TRANSFERT'};
dpNames={'ATTENTE','PARAMETRAGE','CONFIGURATION','ECHANGE','DEFAUT LIAISON'};
v=VideoWriter(files.video,'MPEG-4'); v.FrameRate=6; v.Quality=85; open(v);
sampleTimes=0:0.5:65;
for k=1:numel(sampleTimes)
 i=find(fault.t<=sampleTimes(k),1,'last');
 a=fault.A_L(i); b=fault.B_L(i); ph=fault.phase(i); dp=fault.etatDP(i);
 fluidA.YData=[1.2 1.2 1.2+4.6*a/100 1.2+4.6*a/100];
 fluidB.YData=[1.2 1.2 1.2+4.6*b/100 1.2+4.6*b/100];
 aText.String=sprintf('%.1f L',a); bText.String=sprintf('%.1f L',b);
 timeText.String=sprintf('DEUX CUVES  /  t = %.1f s',fault.t(i));
 if ph==9, phaseName='DEFAUT BUS'; else, phaseName=phaseNames{round(ph)+1}; end
 phaseText.String=['CPU · ' phaseName];
 dpText.String=['DP · ' dpNames{round(dp)+1}];
 if dp==4 || ph==9
  alarmText.String='ALARME : LIAISON PERDUE / COMMANDE EN REPLI';
  alarmText.Color=[.75 .16 .12];
 else
  alarmText.String='Liaison disponible'; alarmText.Color=[.08 .45 .29];
 end
 pumpText.String=sprintf('Pompe : %s   |   VA-03 : %.0f %%',...
  onOff(fault.PMP01(i)),100*fault.positionVA03(i));
 drawnow;
 writeVideo(v,getframe(fig));
end
close(v); close(fig);
fprintf('Supports crees dans %s\n',outdir);
end

function s=onOff(value)
if value>0.5, s='MARCHE'; else, s='ARRET'; end
end
