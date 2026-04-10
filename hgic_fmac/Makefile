hgicf-objs += ctrl.o
hgicf-objs += core.o
hgicf-objs += event.o
hgicf-objs += procfs.o
hgicf-objs += ../utils/fwdl.o
hgicf-objs += ../utils/utils.o
hgicf-objs += ../utils/fwctrl.o
hgicf-objs += ../utils/ota.o
hgicf-objs += ../utils/fwinfo.o
hgicf-objs += ../utils/iwpriv.o
hgicf-$(CONFIG_HGIC_SDIO) += ../utils/if_sdio.o
hgicf-$(CONFIG_HGIC_USB)  += ../utils/if_usb.o


obj-$(CONFIG_HGICF)     += hgicf.o

ccflags-$(CONFIG_HGIC_SDIO) += -DCONFIG_HGIC_SDIO
ccflags-$(CONFIG_HGIC_USB) += -DCONFIG_HGIC_USB
ccflags-$(CONFIG_HGIC_AH) += -DCONFIG_HGIC_AH
ccflags-$(CONFIG_HGIC_2G) += -DCONFIG_HGIC_2G
ccflags-$(CONFIG_SDIO_REINIT) += -DCONFIG_SDIO_REINIT
ccflags-$(CONFIG_HGIC_DMA_ALIGN) += -DSDIO_DMA_ALIGN=4 -DUSB_DMA_ALIGN=4
ccflags-$(CONFIG_COMPILE_ERR_SUPPRESS) += -Wno-date-time -Wno-unused-result -Wno-format -Wno-pointer-to-int-cast