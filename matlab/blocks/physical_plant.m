function y = physical_plant(cmd,bus,u,initialB)
%#codegen
% Volumes L; discretisation 10 ms. Parametres pedagogiques, non identifies.
persistent a b pos spillA spillB
if isempty(a)
    a=0; b=initialB; pos=0; spillA=0; spillB=0;
end
if u(3)>0.5
    a=0; b=initialB; pos=0; spillA=0; spillB=0;
else
    if u(5)>0.5
        target=0; % vanne bloquee fermee
    else
        target=bus(1); % COMMANDE DEPORTEE, pas cmd(5) directement
    end
    pos=pos+min(0.01/0.4,1)*(target-pos);
    qin=2*cmd(1)+3*cmd(2);
    qtransfer=min(4*cmd(4)*pos,a/0.01);
    qdrain=min(3*double(u(6)>0.5),b/0.01);
    rawA=a+0.01*(qin-qtransfer);
    rawB=b+0.01*(qtransfer-qdrain);
    spillA=spillA+max(0,rawA-100);
    spillB=spillB+max(0,rawB-100);
    a=min(100,max(0,rawA)); b=min(100,max(0,rawB));
end
y=[a;b;pos;double(a<=2);double(b>=90);double(pos>=0.95);spillA;spillB];
end
