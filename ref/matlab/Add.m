%file:Add.m  ��Բ�ӷ�
%a,b ��Բ����  p ���� x1,y1 ��һ��������� x2,y2 �ڶ����������
%������P(3,10)��Q(9,7) ����P+Q��[x,y]=Add(1,1,23,3,10,9,7)�õ���� x=17,y=20
function [ resx,resy ] = Add( a,b,p,x1,y1,x2,y2 )

if x1==x2 && y1==y2
    k=modfrac(3*x1^2+a,2*y1,p);
    resx = mod(k^2-x1-x2,p);
    resy = mod(k*(x1-resx)-y1,p);
end

if x1==x2 && y1~=y2
    resx = inf;
    resy = inf;
end

if x1 ~= x2
    k=modfrac(y2-y1,x2-x1,p);
    resx = mod(k^2-x1-x2,p);
    resy = mod(k*(x1-resx)-y1,p);    
end
end