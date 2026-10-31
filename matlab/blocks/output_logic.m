function c = output_logic(phase,p,b,u)
%#codegen
c=zeros(5,1);
if b(5)>0.5 && u(3)<0.5
    c(1)=double(phase==1); c(2)=double(phase==2);
    c(3)=double(phase==3); c(5)=double(phase==4);
    c(4)=double(phase==4 && b(3)>0.5 && b(4)<0.5 && p(4)<0.5);
end
end
