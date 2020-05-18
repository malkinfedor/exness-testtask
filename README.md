
## Тестовое задание для компании exness на позицию devops engeneer.
---
### Содержание задания:

- Развернуть kubernetes-кластер (cреда контейнеризации: K3s or GKE or EKS)

- Операционная система: Linux 

- Веб-сервер: Nginx - any 

- Backend: Php 

- Балансировщик: any 

Написать скрипт, который развернет среду контейнеризации, запустит в ней веб-сервер Nginx и настроит бекенд Php для приема запросов. Скрипт после запуска веб-сервера и бекенда, должен проверить их доступность , используя порты балансировщика.



---
## Описание решения и содержание репозитория
Данный репозитарий является самодостаточным для выполнения указанных выше задач. Достаточно выполнить `git clone` и выполнить указанные шаги по подготовке окружения.

В качестве основного инструмента автоматизации был выбран *ansible* (CM) в связке с _terraform_ (IaC). 

Таким образом для запуска процесса деплоя не машине необходимо только установить _ansible => 2.6_ и _python => 2.7_.
Для удобства установки написан скрипт (адаптирован для debian-like distro) scripts/ansible_install.sh

CI server - Jenkins.

Логика работы следующая:
- ansible role _**tools**_ устанавливает все необходимые инструменты для работы 
- ansible role _**eks-terraform**_ проверяет состояние кластера и, если необходимо, разворачивает кластер с помощью terraform (terraform files находятся в папке _./terraform_)
- ansible role _**deploy**_ разворачивает приложение в созданном кластере. 


**Приложение** и сопутствующие файлы (Dockerfile, kubernetes manifest) находятся в папке ./app. 
Для сборки docker image использовалась следующая команда:
`docker build -f ./app/Dockerfile -t malkinfedor/php-fpm ./app/`

Для развертывания приложения написан kubernetes manifest, который содержит все необходимые сущности для развертывания приложения, а именно:
- _**ConfigMap**_ с кастомными настройками для nginx;
- _**Deployment**_ для развертывания приложения;
- _**Service**_ для доступа к прилжению из внешней сети Internet;
- _**Ingress**_ для доступа к приложению по желаемому URL.


Принято решение создать _Ingress_ и _Service_, так как в текущей реализации не автоматизировано создание DNS записи для _Ingress_ (добавлен пункт в ToDo List).

Выбрана реализация `nginx + php-fpm` в одном pod'e. Тут есть плюсы и минусы, но для тестового приложения вполне годное решение. 
Для высоконагруженного сделал бы отдельне pod'ы для этих двух контейнеров, что бы `scaling` был раздельный.

Минимальная проверка работоспособности реализована с помощью _livenessprobe_ и _readinessProbe_ для обоих контейнеров в pod'e.

---
### Процесс подготовки окружения.
1. `git clone https://github.com/malkinfedor/exness-testtask`
2. Установить ansible посредством скрипта `sudo ./scripts/ansible_install.sh`
3. Авторизоваться под пользователем, под которым будет запускатся ansible playbook в консоли AWS.
Можно использовать один из следующих способов:
- Создать в папке $HOME требуемого пользователя два файла: _$HOME/.aws/credentials_ и _$HOME/.aws/config_ со следующим содержимым
credentials
```sh
cat <<EOF >>$HOME/.aws/credentials
[default]
aws_access_key_id = your_acces_key
aws_secret_access_key = your_secret_acces_key
EOF
```
```sh
cat <<EOF >>$HOME/.aws/config
[default]
region = your_region
output = json
EOF
```
- Выполнить команду `$ aws configure` и последовательно ввести запрашиваемые данные (не подходит для автоматизации)

4. В aws создать S3 bucket и отредактировать в соответствии с ними файл _eks-terraform/backend-conf.tf_

```sh
terraform {
backend "s3" {
   region         = "your_region"
   bucket         = "your_bucket_name"
   key            = "terraform.tfstate"
   encrypt        = "true" # optional
   }
}
```

5. Выдать для пользователя, под которым будет работать ansible-playbook возможность выполнять sudo без пароля. 
Для этого нужно отредактировать файл _/etc/sudoers_ посредством команды `visudo`.
---

#### Примеры запуска ansible playbook
- `ansible-playbook site.yml -i inventory --tags "tools,eks-terraform" -e "user=jenkins"` - для развертывания eks кластера.
- `ansible-playbook site.yml -i inventory --tags "deploy-app" -e "user=jenkins"` - для деплоя приложения.

### Jenkins Job
Для демострации создан Jenkins Job в формате Freestyle на сервере http://java-test.westus.cloudapp.azure.com:8080/(credentials по запросу).

##### ToDo List:
- сделать скрипт установки ansible универсальным (проверять какая ОС и в зависимости от этого выбирать способ установки)
- добавить SSL для Ingress.
- helm chart для деплоя приложения
- добавить автоматизацию создания DNS записи в Route53 (забирать поле ADDRESS для заданного Ingress и создавать CNAME запись в DNS для заданного HOSTS)
- review ansible playbook
- сделать тесты для ansible playbook
