"""Modele de reference independant Python. Ne compile PAS les fichiers MATLAB.
Compare la logique, le bus logique et la physique aux exigences de l'exercice.
"""
from dataclasses import dataclass, field
from pathlib import Path
import itertools,csv,json
DT=.01
@dataclass
class Bus:
    tick:int=0
    age:float=0
    cycles:int=0
    state:int=0
    remote:int=0
    rx:int=0
    data:bool=False
    def step(self,p,c,u):
        if u[2]:self.__dict__.update(Bus().__dict__)
        self.tick+=1;self.age+=DT
        tx=int(c[4])
        if self.tick%2==0 and not u[3]:
            if self.state<3:self.state+=1;self.age=0;self.data=False
            else:
                self.remote=tx&1;self.rx=int(u[1])|(int(p[5])<<1)|(int(p[4])<<2)
                self.age=0;self.cycles+=1;self.data=True
        ok=self.state==3 and self.age<.1 and self.data
        if self.age>=.1 and self.state==3:
            self.remote=0;self.state=0;ok=False;self.data=False
        return [self.remote,self.rx&1,(self.rx>>1)&1,(self.rx>>2)&1,int(ok),self.cycles,self.age,tx,self.rx,self.state]
@dataclass
class Plant:
    initial_b:float=0
    a:float=0
    b:float=0
    pos:float=0
    spill_a:float=0
    spill_b:float=0
    def __post_init__(self):self.b=self.initial_b
    def step(self,c,bus,u):
        if u[2]:self.a=0;self.b=self.initial_b;self.pos=0;self.spill_a=self.spill_b=0
        else:
            target=0 if u[4] else bus[0]
            self.pos+=DT/.4*(target-self.pos)
            qt=min(4*c[3]*self.pos,self.a/DT);qd=min(3*u[5],self.b/DT)
            a=self.a+DT*(2*c[0]+3*c[1]-qt);b=self.b+DT*(qt-qd)
            self.spill_a+=max(0,a-100);self.spill_b+=max(0,b-100)
            self.a=min(100,max(0,a));self.b=min(100,max(0,b))
        return [self.a,self.b,self.pos,int(self.a<=2),int(self.b>=90),int(self.pos>=.95),self.spill_a,self.spill_b]
@dataclass
class Controller:
    phase:int=0
    entered:float=0
    prev1:bool=False
    prev2:bool=False
    def step(self,t,p,b,u):
        s1=bool(u[0]);s2=bool(b[1]);start=(s1 and not self.prev1)or(s2 and not self.prev2)
        self.prev1,self.prev2=s1,s2
        old=self.phase;elapsed=t-self.entered
        if self.phase in (1,2,3,4):
            if not b[4]:self.phase=9
            elif u[2]:self.phase=0
            elif self.phase in (1,2,3) and elapsed>=({1:10,2:5,3:15}[self.phase]-.000001):self.phase+=1
            elif self.phase==4 and p[3]:self.phase=0
        elif self.phase==9:
            if u[2] and b[4]:self.phase=0
        elif start and p[3] and b[4] and not u[2]:self.phase=1
        if old!=self.phase:self.entered=t
        c=[0]*5
        if b[4] and not u[2]:
            c=[int(self.phase==1),int(self.phase==2),int(self.phase==3),int(self.phase==4 and b[2] and not b[3] and not p[3]),int(self.phase==4)]
        return c
SCENARIOS={
 'normal':(0,65,[(0,[0]*6),(1,[1,0,0,0,0,0]),(1.3,[0]*6)]),
 'remote_start':(0,65,[(0,[0]*6),(1,[0,1,0,0,0,0]),(1.3,[0]*6)]),
 'high_B':(85,85,[(0,[0]*6),(1,[1,0,0,0,0,0]),(1.3,[0]*6),(55,[0,0,0,0,0,1]),(80,[0]*6)]),
 'link_loss':(0,65,[(0,[0]*6),(1,[1,0,0,0,0,0]),(1.3,[0]*6),(34,[0,0,0,1,0,0]),(39,[0]*6),(40,[0,0,1,0,0,0]),(40.3,[0]*6)]),
 'stuck_valve':(0,65,[(0,[0,0,0,0,1,0]),(1,[1,0,0,0,1,0]),(1.3,[0,0,0,0,1,0])])}
def run(name):
    initial,stop,events=SCENARIOS[name];plant=Plant(initial);bus=Bus();ctrl=Controller()
    p=[0,0,0,1,0,0,0,0];b=[0]*10;rows=[];u=[0]*6;i=0
    for k in range(round(stop/DT)+1):
        t=round(k*DT,8)
        while i<len(events) and t>=events[i][0]:u=events[i][1];i+=1
        c=ctrl.step(t,p,b,u)
        rows.append([t,ctrl.phase,*p,*b,*c])
        newp=plant.step(c,b,u);newb=bus.step(p,c,u);p,b=newp,newb
    return rows
HEADERS=['t','phase','A_L','B_L','positionVA03','NB_A','NH_B','FDCO','spillA','spillB','VA03_distante','DCY2_recu','FDCO_recu','NH_B_recu','busOK','cycles','age_s','tx0','rx0','etatDP','VA01','VA02','AGT','PMP01','VA03_demandee']
def check(name,rows):
    for r in rows:
        assert 0<=r[2]<=100 and 0<=r[3]<=100
        assert r[8]<1e-9 and r[9]<1e-9
        if r[23]:assert r[1]==4 and r[12] and not r[13] and not r[5] and r[14]
    for phase,expected in [(1,10),(2,5),(3,15)]:
        duration=sum(r[1]==phase for r in rows)*DT
        assert abs(duration-expected)<.031,(name,phase,duration)
    if name in ('normal','remote_start','high_B'):
        assert any(r[23] for r in rows) and rows[-1][1]==0 and rows[-1][2]<=2.05
    if name=='high_B':
        assert any(36<r[0]<54 and r[1]==4 and not r[23] and r[13] for r in rows)
        assert any(r[0]>55 and r[23] for r in rows)
    elif name=='link_loss':
        assert all(r[1]==9 and not any(r[20:]) for r in rows if 34.15<=r[0]<39)
        assert rows[-1][1]==0
    elif name=='stuck_valve':assert not any(r[23] for r in rows) and rows[-1][1]==4
    return {'scenario':name,'passed':True,'durations_s':{str(p):round(sum(r[1]==p for r in rows)*DT,3) for p in [1,2,3]},'final_A_L':rows[-1][2],'final_B_L':rows[-1][3],'cycles_DP':rows[-1][15]}
def main():
    root=Path(__file__).resolve().parents[1];out=root/'validation'/'reference_results';out.mkdir(exist_ok=True)
    reports=[]
    for name in SCENARIOS:
        rows=run(name);reports.append(check(name,rows))
        with (out/(name+'.csv')).open('w',newline='') as f:
            w=csv.writer(f);w.writerow(HEADERS);w.writerows(rows)
    # Verification exhaustive du codage des trois entrees deportees.
    for a,b,c in itertools.product((0,1),repeat=3):
        byte=a|(b<<1)|(c<<2);assert [byte&1,(byte>>1)&1,(byte>>2)&1]==[a,b,c]
    report={'engine':'Python reference only; NOT MATLAB/Simulink execution','scenarios':reports,'payload_combinations':8,'matlab_executed':False}
    (out/'report.json').write_text(json.dumps(report,indent=2))
    print(json.dumps(report,indent=2))
if __name__=='__main__':main()
