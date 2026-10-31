function y = dp_emulator(p,cmd,u,dpMode)
%#codegen
% EMULATION FONCTIONNELLE DP : pas une pile FDL ni une interface RS-485.
% Donnees 16 DI/16 DQ ET200M. Deuxieme octet toujours nul et reserve.
% y: VA03, DCY2, FDCO, NH_B, ok, cycles, age_s, tx0, rx0, etat_DP
persistent tick age cycles lastMode remote rx haveData
if isempty(tick)
    tick=0; age=0; cycles=0; lastMode=-1; remote=0; rx=uint8(0); haveData=false;
end
if u(3)>0.5
    tick=0; age=0; cycles=0; lastMode=-1; remote=0; rx=uint8(0); haveData=false;
end
% Stateflow decide de l'etat du maitre. Ce bloc traite les octets en ECHANGE.
if dpMode~=lastMode
    age=0; haveData=false; remote=0; lastMode=dpMode;
end
tick=tick+1; age=age+0.01;
tx=uint8(0); tx=bitset(tx,1,cmd(5)>0.5);
if dpMode==3 && mod(tick,2)==0 && u(4)<0.5
    % Encode et decode reellement les octets de donnees utilisateur.
    inputBytes=zeros(2,1,'uint8'); outputBytes=zeros(2,1,'uint8');
    outputBytes(1)=tx;
    inputBytes(1)=bitset(inputBytes(1),1,u(2)>0.5);
    inputBytes(1)=bitset(inputBytes(1),2,p(6)>0.5);
    inputBytes(1)=bitset(inputBytes(1),3,p(5)>0.5);
    remote=double(bitget(outputBytes(1),1));
    rx=inputBytes(1); age=0; cycles=cycles+1; haveData=true;
end
ok=double(dpMode==3 && age<0.10 && haveData && u(4)<0.5);
if age>=0.10 || u(4)>0.5
    remote=0; ok=0; haveData=false; % valeur de repli choisie pour la simulation
end
y=[remote;double(bitget(rx,1));double(bitget(rx,2));...
   double(bitget(rx,3));ok;cycles;age;double(tx);double(rx);dpMode];
end
