%file:modfrac.m
% n ����  d ��ĸ   m ģ��
% 2��23ȡģ�Ľ����2����1/2��23��ģ�Ƕ����أ�MATLAB�ﱾ����û�����ּ���ķ�����
% ע�� ������ģ���㣬���Ϊ��������Ҫ����ģ��mת��Ϊ������mod������������
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