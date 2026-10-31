function u = select_inputs(scenario,manual,mode)
%#codegen
u=zeros(6,1);
for k=1:6
    if mode>0.5, u(k)=manual(k); else, u(k)=scenario(k); end
end
end
