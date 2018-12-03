%file:NP.m  ���� ���� ��Բ�ϵĵ�
%a,b ��Բ������p ������n��ʾ n����P���Ҳ����n*P ,x,y ��ʾP��ĺ�������
% ������Ϊ�˼򵥣�ʹ���˵ݹ��ۼӵļ��㷽����
function [resx,resy] = NP( a,b,p,n,x,y )

if n ==1
    resx = x;
    resy = y;
    return;
end
if n>=2
    [xsub,ysub]=NP(a,b,p,n-1,x,y);
    if xsub==Inf && ysub == Inf 
        resx=Inf;
        resy=Inf;
    else
        [resx,resy]=Add(a,b,p,x,y,xsub,ysub);
    end
end
end
