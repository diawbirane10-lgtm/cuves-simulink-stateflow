function [d,initialB,stopTime] = cuves_scenario(name)
% Colonnes : DCY1 DCY2 RESET DEFAUT_BUS VANNE_BLOQUEE VIDANGE_B.
if nargin==0, name='normal'; end
initialB=0; stopTime=65;
switch char(name)
 case 'normal'
  t=[0;1;1.3;65]; v=zeros(4,6); v(2,1)=1;
 case 'held_start'
  % Appui conserve apres la fin du cycle : aucun redemarrage sans front neuf.
  t=[0;1;65]; v=zeros(3,6); v(2:3,1)=1;
 case 'remote_start'
  t=[0;1;1.3;65]; v=zeros(4,6); v(2,2)=1;
 case 'high_B'
  initialB=85; stopTime=85;
  t=[0;1;1.3;55;80;85]; v=zeros(6,6); v(2,1)=1; v(4,6)=1;
 case 'link_loss'
  t=[0;1;1.3;34;39;40;40.3;65]; v=zeros(8,6);
  v(2,1)=1; v(4,4)=1; v(6,3)=1;
 case 'stuck_valve'
  t=[0;1;1.3;65]; v=zeros(4,6); v(:,5)=1; v(2,1)=1;
 case 'link_loss_fill'
  stopTime=20;
  t=[0;1;1.3;5;9;10;10.3;20]; v=zeros(8,6);
  v(2,1)=1; v(4,4)=1; v(6,3)=1;
 case 'reset_during_fill'
  stopTime=12;
  t=[0;1;1.3;4;4.3;12]; v=zeros(6,6);
  v(2,1)=1; v(4,3)=1;
 otherwise
  error('Cuves:Scenario','Scenario inconnu : %s',char(name));
end
d.time=t; d.signals.values=v; d.signals.dimensions=6;
end
