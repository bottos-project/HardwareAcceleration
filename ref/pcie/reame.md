# ubuntu 下  pcie库的操作

https://blog.csdn.net/hpu11/article/details/81876366 

##　1. 2个关键数据结构
PCI设备上有三种地址空间：**PCI的I/O空间、PCI的存储空间和PCI的配置空间**。 CPU可以访问PCI设备上的所有地址空间，其中I/O空间和存储空间提供给设备驱动程序使用，而配置空间则由Linux内核中的PCI初始化代码使用。内核在启动时负责对所有PCI设备进行初始化，配置好所有的PCI设备，包括中断号以及I/O基址，并在文件/proc/pci中列出所有找到的PCI设备，以及这些设备的参数和属性。  

Linux驱动程序通常使用结构（struct）来表示一种设备，而结构体中的变量则代表某一具体设备，该变量存放了与该设备相关的所有信息。好的驱动程序都应该能驱动多个同种设备，每个设备之间用次设备号进行区分，如果采用结构数据来代表所有能由该驱动程序驱动的设备，那么就可以简单地使用数组下标来表示次设备号。
    　　
在PCI驱动程序中，下面几个关键数据结构起着非常核心的作用：
**pci_driver**
    这个数据结构在文件include/linux/pci.h里，这是Linux内核版本2.4之后为新型的PCI设备驱动程序所添加的，其中最主要的是用于识别设备的id_table结构，以及用于检测设备的函数probe( )和卸载设备的函数remove( )：
 ```
struct pci_driver {
   struct list_head node;
    char *name;
    const struct pci_device_id *id_table;
    int (*probe) (struct pci_dev *dev, const struct pci_device_id *id);
    void (*remove) (struct pci_dev *dev);
    int (*save_state) (struct pci_dev *dev, u32 state);
    int (*suspend)(struct pci_dev *dev, u32 state);
    int (*resume) (struct pci_dev *dev);
    int (*enable_wake) (struct pci_dev *dev, u32 state, int enable);
};
 ```
 
**pci_dev**
这个数据结构也在文件include/linux/pci.h里，它详细描述了一个PCI设备几乎所有的硬件信息，包括厂商ID、设备ID、各种资源等：
 ```
struct pci_dev {
    struct list_head global_list;
    struct list_head bus_list;
    struct pci_bus *bus;
    struct pci_bus *subordinate;
 
    void        *sysdata;
    struct proc_dir_entry *procent;
 
    unsigned int    devfn;
    unsigned short vendor;
    unsigned short device;
    unsigned short subsystem_vendor;
    unsigned short subsystem_device;
    unsigned int    class;
    u8      hdr_type;
    u8      rom_base_reg;
 
    struct pci_driver *driver;
    void        *driver_data;
    u64     dma_mask;
    u32             current_state;
 
    unsigned short vendor_compatible[DEVICE_COUNT_COMPATIBLE];
    unsigned short device_compatible[DEVICE_COUNT_COMPATIBLE];
 
    unsigned int    irq;
    struct resource resource[DEVICE_COUNT_RESOURCE];
    struct resource dma_resource[DEVICE_COUNT_DMA];
    struct resource irq_resource[DEVICE_COUNT_IRQ];
 
    char        name[80];
    char        slot_name[8];
    int     active;
    int     ro;
    unsigned short regs;
 
    int (*prepare)(struct pci_dev *dev);
    int (*activate)(struct pci_dev *dev);
    int (*deactivate)(struct pci_dev *dev);
};

