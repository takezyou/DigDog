# Use Case

@startuml
left to right direction
:User:  

User--->(gitlab docker-registry) :imageの登録 tagづけも可能
(gitlab docker-registry)<---(Rails) :image選択可能
User--->(Rails) : Pod作成
(Rails)--->(Kubernetes API)
(Kubernetes API)--->(Server) : Podの立ち上げ・Commandの実行
User--->(kubectl command) : コンテナのdebug・log
(kubectl command)--->(Kubernetes API)  
@enduml
