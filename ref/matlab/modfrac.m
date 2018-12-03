%file:modfrac.m
% n 分子  d 分母   m 模数
% 2对23取模的结果是2，但1/2对23的模是多少呢？MATLAB里本身是没有这种计算的方法的
% 注意 负数的模运算，如果为负数，需要加上模数m转换为正数，mod函数就是这样
function y = modfrac( n,d,m )

n=mod(n,m);
d=mod(d,m);


i=1;
while mod(d*i,m) ~=1
    i=i+1;
end
i
y=mod(n*i,m);
end