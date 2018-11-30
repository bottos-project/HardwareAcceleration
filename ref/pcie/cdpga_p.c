/*
 * Software License Agreement (GPL License)
 *
 * Copyright (c) 2018, DUKELEC, Inc.
 * All rights reserved.
 *
 * Author: Duke Fong <duke@dukelec.com>



 */

#define DEBUG

#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/module.h>
#include <linux/pci.h>
//#include <unistd.h> //

#define DRV_NAME "cdpga_p"
#define BAR_NUM 1

typedef struct {
    struct pci_dev  *dev;
	void __iomem    *bar_va[BAR_NUM];
} cdp_t;


// 指向设备检测函数prob( ) 的指针。
// 该函数将在pci设备ID与设备ID表匹配且还没有被其它驱动程序处理时（一般在对已存在的设备执行pci_register_driver或以后又有新设备插入时）被调用。
// 调用时传入一个指向struct pci_driver结构的指针和与设备匹配的设备ID表做参数。若成功（驱动程序检测到pci设备）则返回0，否则返回一个负的错误代码。
// 这个函数总是在上下文之间调用，因此可以进入睡眠状态的。
static int cdp_probe(struct pci_dev *dev, const struct pci_device_id *id)
{
    int ret, bar = 0;
    cdp_t *cdp;

    dev_dbg(&dev->dev, " %s\n", __FUNCTION__);

    /* 启动PCI设备 */
    ret = pci_enable_device(dev);
    if (ret) {
        dev_err(&dev->dev, "pci_enable_device err: %d!\n", ret);
        return ret;
    }
    
    /* 在内核空间中动态申请内存 */
	cdp = kzalloc(sizeof(cdp_t), GFP_KERNEL);
	if (!cdp) {
		ret = -ENOMEM;
		goto err_alloc;
	}
	

    cdp->dev = dev;
    /* 设置总线模式 */   
    //为pci_dev设置私有数据指针
    pci_set_drvdata(dev, cdp);


    //使用MSI中断，需先调用pci_enable_msi() 初始化设备MSI中断结构
    //使能msi，然后才能得到pdev->irq
    ret = pci_enable_msi(dev);
    if (ret) {
        dev_err(&dev->dev, "pci_enable_msi err: %d!\n", ret);
        goto err_msi;
    }

    //函数通知内核，当前PCI将使用这些内存地址，其他设备不能再使用了
    ret = pci_request_regions(dev, DRV_NAME);
    if (ret) {
        dev_err(&dev->dev, "pci_request_regions err: %d!\n", ret);
        goto err_regions;
    }

    //获得io映射地址  将获得内存地址转换成虚拟地址 
    cdp->bar_va[bar] = pci_iomap(dev, bar, 0);
    if (!cdp->bar_va[bar]) {
        dev_err(&dev->dev, "pci_iomap err!\n");
        ret = -1;
        goto err_map;
    }

    dev_dbg(&dev->dev, "cdp_probe successful\n");

    {
	uint32_t *reg_data = cdp->bar_va[bar]； //IO口首地址，对应数据读写
        uint32_t *reg_dir = cdp->bar_va[bar] + 4;//表示加4个字节的偏移32bit，IO口第二个地址，对应IO口方向

        dev_dbg(&dev->dev, "%p: %08x\n", reg_dir, *reg_dir);

        *reg_dir = 0xffff;//设置方向为输出，默认值为0

        dev_dbg(&dev->dev, "%p: %08x\n", reg_dir, *reg_dir);

	while(1)
	{
	*reg_data  = 0x7fff; //最高2bit设置为01
	//sleep(3); //延时3s
	*reg_data  = 0x8fff ;//最高2bit设置为10
	//sleep(3);
	*reg_data  = 0x0fff; //最高2bit设置为00
	//sleep(3);
	*reg_data  = 0xffff ;//最高2bit设置为11
	}

    }

    return 0;

err_map:
    pci_release_regions(dev);
err_regions:
    pci_disable_msi(dev);
err_msi:
    kfree(cdp);
    pci_set_drvdata(dev, NULL);
err_alloc:
    pci_disable_device(dev);

    return ret;
}

static void cdp_remove(struct pci_dev *dev)
{
    int bar = 0;
    cdp_t *cdp = pci_get_drvdata(dev);

    dev_dbg(&dev->dev, " %s\n", __FUNCTION__);

    if (cdp->bar_va[bar]) {
        pci_iounmap(dev, cdp->bar_va[bar]);
        cdp->bar_va[bar] = NULL;
    }

    pci_release_regions(dev);
    pci_disable_msi(dev);
    pci_set_drvdata(dev, NULL);
    pci_disable_device(dev);
}

//指定PCI设备：
//根据设备的id填写,这里假设厂商id和设备id
static const struct pci_device_id ids[] = {
    { PCI_DEVICE(0x1172, 0x0004), },
    { 0, }
};
MODULE_DEVICE_TABLE(pci, ids);

//关键数据结构：
//其中最主要的是用于识别设备的id_table结构，以及用于检测设备的函数probe( )和卸载设备的函数remove( )：
//设备模块信息：
static struct pci_driver cdp_driver = {
    .name = DRV_NAME,   /* 设备模块名称 */
    .id_table = ids, /* 能够驱动的设备列表 */
    .probe = cdp_probe,    /* 查找并初始化设备，驱动主函数 */
    .remove = cdp_remove   /* 卸载设备模块 */
};

/* 加载驱动程序模块入口 */
static int __init cdp_init(void)
{
    int ret;
    pr_debug(DRV_NAME " %s\n", __FUNCTION__);

     /* 检查系统是否支持PCI总线 */
    if (!pci_present())
        return -1;

    /* 注册硬件驱动程序 */
    ret = pci_register_driver(&cdp_driver);
    if (ret < 0)
         pci_unregister_driver(&cdp_driver);
        return  -1;

    return 0;
}

/* 卸载驱动程序模块入口 */
static void __exit cdp_exit(void)
{
    pr_debug(DRV_NAME " %s\n", __FUNCTION__);
    pci_unregister_driver(&cdp_driver);
}

MODULE_LICENSE("GPL");
module_init(cdp_init);
module_exit(cdp_exit);
