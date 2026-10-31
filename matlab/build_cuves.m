function model = build_cuves()
% Genere un vrai .slx dans generated/ a partir des sources inspectables.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab')); addpath(fullfile(root,'matlab','blocks'));
assert(license('test','Simulink'),'Simulink est requis.');
assert(license('test','Stateflow'),'Stateflow est requis.');
model='Cuves_PROFIBUS_Stateflow';
if bdIsLoaded(model), close_system(model,0); end
load_system('simulink'); load_system('sflib'); new_system(model);
set_param(model,'SolverType','Fixed-step','Solver','FixedStepDiscrete',...
 'FixedStep','0.01','StopTime','65','SimulationMode','normal',...
 'ReturnWorkspaceOutputs','on','BlockReduction','off','OptimizeBlockIOStorage','off');
[d,~,~]=cuves_scenario('normal');
ws=get_param(model,'ModelWorkspace'); assignin(ws,'scenarioData',d);
add_block('simulink/Sources/From Workspace',[model '/Scenario'],...
 'VariableName','scenarioData','Interpolate','off',...
 'OutputAfterFinalValue','Holding final value','SampleTime','0.01',...
 'Position',[25 35 160 70]);
add_block('simulink/Sources/Constant',[model '/ManualInputs'],...
 'Value','[0;0;0;0;0;0]','SampleTime','0.01','Position',[25 105 160 140]);
add_block('simulink/Sources/Constant',[model '/ManualMode'],...
 'Value','0','SampleTime','0.01','Position',[25 175 160 210]);
add_block('simulink/Sources/Constant',[model '/InitialB'],...
 'Value','0','SampleTime','0.01','Position',[850 455 940 485]);
func('SelectInputs','select_inputs.m',[210 65 360 185]);
func('CPU_IO','cpu_inputs.m',[430 90 580 235]);
func('Commands','output_logic.m',[850 95 1000 225]);
func('DP_Emulator','dp_emulator.m',[430 355 620 490]);
func('Plant','physical_plant.m',[850 305 1010 430]);
add_block('simulink/Discrete/Unit Delay',[model '/PlantState'],...
 'SampleTime','0.01','InitialCondition','[0;0;0;1;0;0;0;0]',...
 'Position',[1080 325 1140 380]);
add_block('simulink/Discrete/Unit Delay',[model '/BusState'],...
 'SampleTime','0.01','InitialCondition','zeros(10,1)',...
 'Position',[680 365 740 425]);
add_block('sflib/Chart',[model '/Sequence'], 'Position',[650 90 780 235]);
add_block('simulink/Signal Routing/Demux',[model '/DP_Inputs'],...
 'Outputs','6','Position',[210 365 215 485]);
add_block('simulink/Signal Routing/Demux',[model '/DP_Bus'],...
 'Outputs','10','Position',[765 365 770 465]);
add_block('sflib/Chart',[model '/DP_Control'], 'Position',[260 355 390 490]);
add_block('simulink/Math Operations/Gain',[model '/PhaseView'],'Gain','1','Position',[790 60 825 85]);
add_block('simulink/Math Operations/Gain',[model '/CommandView'],'Gain','1','Position',[1020 170 1060 205]);
rt=sfroot; ch=rt.find('-isa','Stateflow.Chart','Path',[model '/Sequence']);
ch.ActionLanguage='MATLAB'; ch.ChartUpdate='DISCRETE'; ch.SampleTime='0.01';
ch.UserSpecifiedStateTransitionExecutionOrder=true;
ins={'start','low','busok','reset'};
for k=1:numel(ins)
 x=Stateflow.Data(ch); x.Name=ins{k}; x.Scope='Input'; x.Port=k; x.DataType='double';
end
x=Stateflow.Data(ch); x.Name='phase'; x.Scope='Output'; x.Port=1; x.DataType='double';
idle=Stateflow.State(ch); idle.Position=[50 160 215 105];
idle.LabelString=sprintf('ATTENTE\nentry:\n phase = 0;\nduring:\n phase = 0;');
cycle=Stateflow.State(ch); cycle.Position=[350 65 1130 260];
cycle.LabelString='CYCLE_CPU';
fault=Stateflow.State(ch); fault.Position=[790 430 230 105];
fault.LabelString=sprintf('DEFAUT_BUS\nentry:\n phase = 9;\nduring:\n phase = 9;');
names={'REMPLISSAGE_P1','REMPLISSAGE_P2','AGITATION','TRANSFERT'};
st=cell(1,4);
for k=1:4
 st{k}=Stateflow.State(cycle);
 st{k}.Position=[385+275*(k-1),165,230,105];
 st{k}.LabelString=sprintf('%s\nentry:\n phase = %d;\nduring:\n phase = %d;',names{k},k,k);
end
tr=Stateflow.Transition(ch); tr.Destination=idle; tr.DestinationOClock=0;
tr.SourceEndpoint=[157 100]; tr.Midpoint=[157 130];
tr=Stateflow.Transition(cycle); tr.Destination=st{1}; tr.DestinationOClock=0;
tr.SourceEndpoint=[500 120]; tr.Midpoint=[500 145];
% Le parent CYCLE_CPU centralise les interverrouillages des quatre etapes.
z=trans(ch,idle,cycle,'[start > 0.5 && low > 0.5 && busok > 0.5 && reset < 0.5]',1,3,9);
z.LabelPosition=[270 105 500 20];
trans(ch,cycle,fault,'[busok < 0.5]',1,6,0);
trans(ch,cycle,idle,'[reset > 0.5]',2,0,0);
trans(ch,cycle,idle,'[phase == 4 && low > 0.5]',3,6,6);
trans(ch,fault,idle,'[reset > 0.5 && busok > 0.5]',1,9,6);
z=trans(cycle,st{1},st{2},'after(10,sec)',1,3,9);
z.LabelPosition=[590 135 135 20];
z=trans(cycle,st{2},st{3},'after(5,sec)',1,3,9);
z.LabelPosition=[865 135 120 20];
z=trans(cycle,st{3},st{4},'after(15,sec)',1,3,9);
z.LabelPosition=[1140 135 135 20];
% Le maitre DP est une seconde machine Stateflow. L'ET200M reste une
% station d'E/S deportees : elle n'execute aucun programme automate.
dpch=rt.find('-isa','Stateflow.Chart','Path',[model '/DP_Control']);
dpch.ActionLanguage='MATLAB'; dpch.ChartUpdate='DISCRETE'; dpch.SampleTime='0.01';
dpch.UserSpecifiedStateTransitionExecutionOrder=true;
dpins={'linkLost','resetDP','ageDP'};
for k=1:numel(dpins)
 x=Stateflow.Data(dpch); x.Name=dpins{k}; x.Scope='Input'; x.Port=k; x.DataType='double';
end
x=Stateflow.Data(dpch); x.Name='dpMode'; x.Scope='Output'; x.Port=1; x.DataType='double';
dpIdle=Stateflow.State(dpch); dpIdle.Position=[50 150 215 100];
dpIdle.LabelString=sprintf('ATTENTE\nentry:\n dpMode = 0;\nduring:\n dpMode = 0;');
dpActive=Stateflow.State(dpch); dpActive.Position=[345 65 880 260];
dpActive.LabelString='SERVICE_DP';
dpFault=Stateflow.State(dpch); dpFault.Position=[660 415 260 100];
dpFault.LabelString=sprintf('DEFAUT_LIAISON\nentry:\n dpMode = 4;\nduring:\n dpMode = 4;');
dpnames={'PARAMETRAGE','CONFIGURATION','ECHANGE'}; dpst=cell(1,3);
for k=1:3
 dpst{k}=Stateflow.State(dpActive);
 dpst{k}.Position=[380+280*(k-1),165,240,105];
 dpst{k}.LabelString=sprintf('%s\nentry:\n dpMode = %d;\nduring:\n dpMode = %d;',...
  dpnames{k},k,k);
end
z=Stateflow.Transition(dpch); z.Destination=dpIdle; z.DestinationOClock=0;
z.SourceEndpoint=[157 90]; z.Midpoint=[157 120];
z=Stateflow.Transition(dpActive); z.Destination=dpst{1}; z.DestinationOClock=0;
z.SourceEndpoint=[500 120]; z.Midpoint=[500 145];
dptrans(dpch,dpIdle,dpFault,'[linkLost > 0.5]',1,6,9);
z=dptrans(dpch,dpIdle,dpActive,'after(0.02,sec)',2,3,9);
z.LabelPosition=[265 120 160 20];
dptrans(dpch,dpActive,dpFault,'[linkLost > 0.5 || (dpMode == 3 && ageDP >= 0.10)]',1,6,0);
z=dptrans(dpch,dpActive,dpIdle,'[resetDP > 0.5]',2,0,0);
z.LabelPosition=[120 60 130 20];
dptrans(dpch,dpFault,dpIdle,'[linkLost < 0.5]',1,9,6);
z=dptrans(dpActive,dpst{1},dpst{2},'after(0.02,sec)',1,3,9);
z.LabelPosition=[620 135 160 20];
z=dptrans(dpActive,dpst{2},dpst{3},'after(0.02,sec)',1,3,9);
z.LabelPosition=[900 135 160 20];
% Defaut vanne: attente a l'etape 4, pas de pompe; aucune temporisation ajoutee.
wire('Scenario/1','SelectInputs/1'); wire('ManualInputs/1','SelectInputs/2');
wire('ManualMode/1','SelectInputs/3');
wire('PlantState/1','CPU_IO/1'); wire('BusState/1','CPU_IO/2'); wire('SelectInputs/1','CPU_IO/3');
for k=1:4, wire(sprintf('CPU_IO/%d',k),sprintf('Sequence/%d',k)); end
wire('Sequence/1','PhaseView/1'); wire('PhaseView/1','Commands/1'); wire('PlantState/1','Commands/2');
wire('BusState/1','Commands/3'); wire('SelectInputs/1','Commands/4');
wire('SelectInputs/1','DP_Inputs/1'); wire('BusState/1','DP_Bus/1');
wire('DP_Inputs/4','DP_Control/1'); wire('DP_Inputs/3','DP_Control/2');
wire('DP_Bus/7','DP_Control/3');
wire('Commands/1','CommandView/1'); wire('PlantState/1','DP_Emulator/1'); wire('CommandView/1','DP_Emulator/2');
wire('SelectInputs/1','DP_Emulator/3'); wire('DP_Control/1','DP_Emulator/4');
wire('DP_Emulator/1','BusState/1');
wire('CommandView/1','Plant/1'); wire('BusState/1','Plant/2');
wire('SelectInputs/1','Plant/3'); wire('InitialB/1','Plant/4'); wire('Plant/1','PlantState/1');
logsignal('PlantState','plantLog',[1200 290 1300 320]);
logsignal('BusState','busLog',[760 490 860 520]);
logsignal('CommandView','cmdLog',[1080 105 1180 135]);
logsignal('PhaseView','phaseLog',[820 25 920 55]);
set_param(model,'SimulationCommand','update'); % compilation obligatoire
outdir=fullfile(root,'generated'); if ~isfolder(outdir), mkdir(outdir); end
save_system(model,fullfile(outdir,[model '.slx']));
fprintf('Modele genere et compile : %s\n',fullfile(outdir,[model '.slx']));
 function func(name,file,pos)
  path=[model '/' name]; add_block('simulink/User-Defined Functions/MATLAB Function',path,'Position',pos);
  r=sfroot; f=r.find('-isa','Stateflow.EMChart','Path',path);
  f.Script=fileread(fullfile(root,'matlab','blocks',file));
  if isprop(f,'VectorOutputs1D'), f.VectorOutputs1D=true; end
  f.ChartUpdate='DISCRETE'; f.SampleTime='0.01';
 end
 function wire(src,dst), add_line(model,src,dst,'autorouting','on'); end
 function z=trans(parent,a,b,label,order,srcClock,dstClock)
  z=Stateflow.Transition(parent); z.Source=a; z.Destination=b;
  z.SourceOClock=srcClock; z.DestinationOClock=dstClock;
  z.LabelString=label; z.ExecutionOrder=order;
 end
 function z=dptrans(parent,a,b,label,order,srcClock,dstClock)
  z=Stateflow.Transition(parent); z.Source=a; z.Destination=b;
  z.SourceOClock=srcClock; z.DestinationOClock=dstClock;
  z.LabelString=label; z.ExecutionOrder=order;
 end
 function logsignal(src,var,pos)
  name=['Log_' var]; add_block('simulink/Sinks/To Workspace',[model '/' name],...
   'VariableName',var,'SaveFormat','Structure With Time','Position',pos);
  wire([src '/1'],[name '/1']);
 end
end
