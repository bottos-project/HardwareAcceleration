# description
   crypto alg and signature alg cost much computering resources. To improve performance , we wish some costs in special hardware such
   as FPGA. 

   
# features
     support ecdsa alg through fpga;
     support parralled calling 
     ip can be  deplyed in cloud fpga instance
     
# 构思
## 概念：
### ECDSA签名算法：
ECDSA是ECC与DSA的结合，整个签名过程与DSA类似，所不一样的是签名中采取的算法为ECC，最后签名出来的值也是分为r,s。
#### 签名过程如下：
1. 选择一条椭圆曲线Ep(a,b)，和基点G；
2. 选择私有密钥k（k<n，n为G的阶），利用基点G计算公开密钥K=kG；
3.产生一个随机整数r（r<n），计算点R=rG；
4. 将原数据和点R的坐标值x,y作为参数，计算SHA1做为hash，即Hash=SHA1(原数据,x,y)；
5. 计算s≡r - Hash * k (mod n)
6、r和s做为签名值，如果r和s其中一个为0，重新从第3步开始执行
#### 验证过程如下：
1. 接受方在收到消息(m)和签名值(r,s)后，进行以下运算
2. 计算：sG+H(m)P=(x1,y1), r1≡ x1 mod p。
3. 验证等式：r1 ≡ r mod p。
4. 如果等式成立，接受签名，否则签名无效。
#### 注意：
1. ECDSA只能签名256位的消息，但是这个并不是一个主要问题，因为消息在签名前都经过了哈希运算，这样可以导致任何长度的消息都可以被签名。
2. ECDSA签名算法而言，一个好的随机源是非常重要的，因为比较差的随机源会导致你的私钥泄露。泄露了你的私钥，那么黑客就可以伪造你的签名。
## Secp256k1：
Secp256k1为基于Fp有限域上的Koblitz椭圆曲线，由于其特殊构造的特殊性，其优化后的实现比其他曲线性能上可以特高30％，有明显以下两个优点：
1. 占用很少的带宽和存储资源，密钥的长度很短。
2. 让所有的用户都可以使用同样的操作完成域运算。


通常将Fp上的一条椭圆曲线描述为T=(p,a,b,G,n,h)，p、a、b确定一条椭圆曲线（p为质数，(mod p)运算），G为基点，n为点G的阶，h是椭圆曲线上所有点的个数m与n相除的商的整数部分
比特币系统选用的secp256k1中，参数为
> p = 0xFFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFE FFFFFC2F
>
> = 2^256 − 2^32 − 2^9 − 2^8 − 2^7 − 2^6 − 2^4 − 1
>
> a = 0， b = 7
>
> G=(0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8)
>
> n = 0xFFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFE BAAEDCE6 AF48A03B BFD25E8C D0364141

> h = 01

### 签名运算：
#### （1）已知
1. 椭圆曲线T=(p,a,b,G,n,h)的各参数(secp256k1)
2. 私钥k；
3. 公钥K =k*G；
4. 原数据m； 
#### （2）运算过程	
1. 产生一个随机整数r（r<n），计算点R=rG
2. 原数据m和点R的坐标值x,y作为参数，计算SHA1做为hash，即Hash=SHA1(原数据,x,y)；
3. 计算签名值s ≡ r - Hash * k (mod n)
#### 得到签名值
1. r和s为需要的签名值；
2. 如果r和s其中一个为0，重新产生r和s；

### 关键点：
1. 计算椭圆上的点R，需要使用椭圆上的计算方法，是否可参考公钥的生成？是否上位机可使用公钥的产生方式直接得到点R的x与y的值？
2. Hash运算，待了解；
3. Hash*k这个是256bit乘法运算，而不是椭圆上的点运算？
4. r-Hash*k (mod n)这个数为一个负数的求模运算？ 

#### 注意点：
1. G点取标准的256bit还是512bit？ 
2. Hash与k同为256bit，那么Hash*k为512bit，签名值s取512bit？
3. 签名值r为256bit，s为512bit？
4. 签名是使用私钥k还是公钥K？
