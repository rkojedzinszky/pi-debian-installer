# Bootloader

From https://github.com/radxa-repo/bsp.git

Add `BSP_BL31_VARIANT=""` at the end of `bsp_radxa-zero3()`:

```diff
diff --git a/u-boot/latest/fork.conf b/u-boot/latest/fork.conf
index 892c747..34a3910 100644
--- a/u-boot/latest/fork.conf
+++ b/u-boot/latest/fork.conf
@@ -148,6 +148,7 @@ bsp_radxa-cm3i-io() {
 
 bsp_radxa-zero3() {
     bsp_rk3566
+    BSP_BL31_VARIANT=""
 }
 
 bsp_radxa-cm3-sodimm-io() {
```

```sh
$ ./bsp u-boot latest radxa-zero3
```

Files: ./.src/u-boot/idbloader.img, ./.src/u-boot/u-boot.itb
