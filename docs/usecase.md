# Use Case

```
@startuml
left to right direction
:User:  

User--->(Rails) : Pod作成
(Rails)--->(Kubernetes API)
(Kubernetes API)--->(Server) : Podの立ち上げ・Commandの実行
User--->(kubectl command) : コンテナのdebug・log
(kubectl command)--->(Kubernetes API)  
@enduml
```
