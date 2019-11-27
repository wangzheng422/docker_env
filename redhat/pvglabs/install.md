
```
https://wuzhaojun.wordpress.com/2017/05/05/a-workaround-to-fix-unsigned-jnlp-issue-after-upgrade-java-to-version-8-update-131/

Just comment out the setting of jdk.jar.disabledAlgorithms in the file of lib/security/java.security (which is located at /Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/lib/security/java.security, on my MacOS 10.12)

# jdk.jar.disabledAlgorithms=MD2, MD5, RSA keySize < 1024

```