#运算过程 - 参考go语言库 D:\Go\src\crypto\ecdsa

PrivateKey 代表 ECDSA 私钥。

type PrivateKey struct {
        PublicKey
        D *big.Int
}

type PublicKey struct {
        elliptic.Curve
        X, Y *big.Int
}

签名函数： 输入随机值（<256b）,私钥和散列值
r, s, err := Sign(rand.Reader, priv, hash[:])
