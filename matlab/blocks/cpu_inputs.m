function [start,low,busok,reset] = cpu_inputs(p,b,u)
%#codegen
persistent old1 old2
if isempty(old1), old1=false; old2=false; end
s1=u(1)>0.5; s2=b(2)>0.5;
start=double((s1 && ~old1) || (s2 && ~old2));
old1=s1; old2=s2;
low=p(4); busok=b(5); reset=u(3);
if reset>0.5, start=0; end
end
