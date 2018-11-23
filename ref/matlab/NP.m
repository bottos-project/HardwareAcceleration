%file:NP.m  常数 乘以 椭圆上的点
%a,b 椭圆参数，p 质数，n表示 n个点P相加也就是n*P ,x,y 表示P点的横纵坐标
% （这里为了简单，使用了递归累加的计算方法）
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
