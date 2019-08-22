設定ファイルについて

## 以下に記述されているファイルはcommitされてないので注意!!
(一応機密情報なので)

- config/k8s_config.yml
  - k8sのgemにて使用
  - hackmdに記述されているのをコピペして保存すれば最低限は動く

- config/ldap.yml
  - LDAP認証にて使用
  - 以下をコピペして必要な部分を保存
  ```
  development:
    host: "<LDAPサーバのアドレス>"
    port: 389
    attribute: cn
    base: "<basedn>"
    admin_user: "<adminユーザー>"
    admin_password: "<adminユーザーのパスワード>"
    ssl: false
  ```
