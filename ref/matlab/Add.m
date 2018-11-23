%file:Add.m  椭圆加法
%a,b 椭圆参数  p 质数 x1,y1 第一个点的坐标 x2,y2 第二个点的坐标
%如两点P(3,10)，Q(9,7) 计算P+Q：[x,y]=Add(1,1,23,3,10,9,7)得到结果 x=17,y=20
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