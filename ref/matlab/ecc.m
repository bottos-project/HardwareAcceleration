% file:ECC.m
%演示曲线加密算法加/解密过程
% https://blog.csdn.net/alphags/article/details/79660819
a=4;
b=20;
p=29;
GX=13;
GY=23;
k=25;
[KX,KY]=NP(a,b,p,k,GX,GY)

r=6

MX = 3
MY = 28

[rKX,rKY] = NP(a,b,p,r,KX,KY)

[C1X,C1Y]=Add(a,b,p,MX,MY,rKX,rKY)

[C2X,C2Y]=NP(a,b,p,r,GX,GY)


[kC2X,kC2Y]=NP(a,b,p,k,C2X,C2Y);

kC2Y=mod(-1*kC2Y,p)

[resx,resy]=Add(a,b,p,C1X,C1Y,kC2X,kC2Y)
