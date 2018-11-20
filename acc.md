# 关于公钥与私钥
 参考go语言库 D:\Go\src\crypto\ecdsa

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
1)  输入随机值（<256b）: 私钥的安全性，取决与该随机数的产生，长度小于32byte（256bit）
2)  私钥:  为在[1，secp256k1n - 1]范围内随机选择的正整数，长度小于256bit
3)  散列值： 为任意长度信息的散列值，也称信息摘要，为SHA-512 hash计算结果，长度256bit

