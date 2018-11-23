# 关于公钥与私钥
 参考go语言库 D:\Go\src\crypto\ecdsa
 goland 的 ECDSA库的椭圆运算，使用了另一个椭圆运算库（不易参考）：https://www.hyperelliptic.org/EFD/g1p/auto-shortw.html

PrivateKey 代表 ECDSA 私钥。

type PrivateKey struct {
        PublicKey
        D *big.Int
}

type PublicKey struct {
        elliptic.Curve
        X, Y *big.Int
}

> 
> **elliptic.Curve** 
> 接口声明了椭圆曲线的相关操作方法，其中Add()方法就是椭圆曲线点倍积中的“点相加”操作，Double()就是点倍积中的“点翻倍”操作，ScalarMult()根本就是一个点倍积运算（参数k是标量），IsOnCurve()检查参数所代表的点是否在该椭圆曲线上；
> 

> **私钥**
> *ecdsa.PrivateKey*是暴露给外部使用的主要结构体类型，它其实是算法理论中的私钥和公钥的集合。*它的成员D，才真正对应于算法理论中的(标量)私钥*。成员PublicKey包含椭圆曲线的信息，以及公钥的x,y值。

> **公钥**
> *ecdsa.PrivateKey.PublicKey*为公钥的结构体，使用的公钥压缩格式只取x值，因为y值可以通过x计算出来。非压缩格式的两个值分别为x值与y值
> 公钥：在secp256k1规范下，由私钥和规范中指定的生成点计算出的坐标(x, y)
>      非压缩格式公钥： [前缀0x04] + x + y (65字节)
>      压缩格式公钥：[前缀0x02或0x03] + x ，其中前缀取决于 y 的符号

# 签名算法-函数解读 #
r, s, err := Sign(rand.Reader, priv, hash[:])

**输入**
1)  输入随机值r(r<n) : 私钥的安全性，取决与该随机数的产生，长度小于32byte（256bit）
2)  私钥D:  为在[1，secp256k1n - 1]范围内随机选择的正整数，长度小于256bit
3)  散列值e： 为任意长度信息的散列值，也称信息摘要，为SHA-512 hash计算结果，长度256bit

**计算过程**
1. 散列值转换为整数得到e  ： e := hashToInt(hash, c)
2. 计算签名值r值：  
        产生一个随机数k：           k, err = randFieldElement(c, csprng)
        计算椭圆上的点R = k*G  :    r, _ = priv.Curve.ScalarBaseMult(k.Bytes())
        签名值r 为点R（x，y）的x值     
3. 计算签名值s值：
        s = （e + DkG）* 1/k 
        其中e 为散列值，k为随机数  ----> e/k 为随机值
        D为私钥，G为基点---->


签名值为：{r ，s} 


必不可少的匀速： 256bit加法、 256bit乘法、256bit模运算

http://blog.51cto.com/11821908/2057726


# 算法梳理
### 签名运算：
#### （1）已知
1. 椭圆曲线T=(p,a,b,G,n,h)的各参数(secp256k1)
2. 私钥k；
3. 公钥K = k*G；
4. 原数据或散列值m
#### （2）运算过程	
1. 计算签名值Sig.R ： （需小于n，所以需要与n求模，椭圆曲线中求模运算不影响加密特性）
>         产生一个随机整数r（r<n），计算点R=rG  ;
>         提取R的坐标值（x,y）中的x值为为签名值Sig.R； 

2. 计算签名值Sig.S
>       计算乘法 (Sig.R) * k;         
>       计算加法 (Sig.R) * k + m  ;     
>       计算随机数在椭圆上的的逆 1/r  ;   
>       计算乘法Sig.S = ((Sig.R) * k + m ) * (1/r);

3. 关于求模运算，可以计算的每一步求模，也可以最终结果求模，不影响最终计算结果。求模的目的是限定最终的数据范围为1~n-1之间的数

4. 椭圆运算：仅Sig.R的运算为椭圆运算，但椭圆运算中涉及了多个加减乘除运算，应该是一个难点。

5. 注意：求逆运算与求模运算的规则，相对传统的逆运算与求模运算有一定的扩展，需要特别注意。


### 函数：
主要参考：https://github.com/haltingstate/secp256k1-go
该库使用了高精度计算库 GMP ：https://gmplib.org/
但该函数库与go语言自身的ECDSA库，计算方法相同。

// func (sig *Signature) Sign(seckey, message, nonce *Number, recid *int)
//输入：
//	seckey   私钥 256bit  ，   公式中为k
//	nonce   随机数256bit  ，   公式中为r
//	message  任意长度信息 ，   公式中为Hash
//输出:   
//  recid：64*8=512bit签名信息
//计算过程：
//	设随机数为r，私钥为k
//	计算R的值(x,y)，R = r * G ，其中r为随机数，程序中为nonce，G为椭圆基点
//  签名值R：取点R(x,y)的x轴数值  , 依然为椭圆曲线上的一个随机数；
//  签名值S: S  = (k*R + Hash) * 1/r
//	       =  (k*r*G + hash） * 1/r

func (sig *Signature) Sign(seckey, message, nonce *Number, recid *int) int {
	var r XY
	var rp XYZ
	var n Number
	var b [32]byte

	ECmultGen(&rp, nonce)  //通过随机数r：nonce，  计算点R=rG （rp = nonce * G）
	r.SetXYZ(&rp) //获取rp的（x，y）
	r.X.Normalize()
	r.Y.Normalize()
	r.X.GetB32(b[:]) //  把r.x转换为字节矩阵 传递给b
	sig.R.SetBytes(b[:]) // 将b转换为一个整形得到  R = R.x

	sig.R.mod(&TheCurve.Order)  // R = R mode n
	n.mod_mul(&sig.R, seckey, &TheCurve.Order) //n = R * seckey  mode n
	n.Add(&n.Int, &message.Int)                //n = R * seckey  mode n  + message
	n.mod(&TheCurve.Order)                     //n =(R * seckey + message  ) mode n  
	sig.S.mod_inv(nonce, &TheCurve.Order)      //S = 1/nonce   *  (R * seckey + message)
	sig.S.mod_mul(&sig.S, &n, &TheCurve.Order)

	return 1
}


# 具体运算
## 求模运算
椭圆曲线签名算法，主要求模对象为椭圆的阶n
 n = 0xFFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFE BAAEDCE6 AF48A03B BFD25E8C D0364141
 n的补码为n取反加1有：
-n = 0x00000000 00000000 00000000 00000001 45512319 50B75FC4 402DA173 2FC9BEBF

签名运算中，存在的求模运算为，和与积的求模。

求模运算中n与p的关系：
p: 我们给出一个有限域Fp，Fp中有p（p为质数）个元素0,1,2,…, p-2,p-1；
n：如果椭圆曲线上一点G，存在最小的正整数n使得数乘nG=O∞ ,则将n称为P的阶，因此与G点相关点最多只有n个。

**加法求模：**
- 因被加数都小于n，所以求和后与n相除的整数部分为0~2，因此两步计算即可
	
		C = A + B mod P
      {
	    S = A + B；
		T = S - P；
		C = (T<0) ?  S : T;	 
	  }
 	

 **乘法求模：**
 先做乘法256bit的两个数相乘，乘积后为512bit，做除法取余数。
 使用移位除法的方式，需要256个时钟运算周期，可以接受。
 
 **分数求模：**
 
 


maltab-ECC加密解密算法：https://blog.csdn.net/alphags/article/details/79660819
快速约减，求模运算：https://my.oschina.net/safedead/blog/1541809
